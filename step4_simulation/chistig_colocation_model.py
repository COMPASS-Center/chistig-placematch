import sys
import re
import math
import pandas as pd
import numpy as np
from typing import Dict, Tuple
from mpi4py import MPI
from dataclasses import dataclass
import random 
import yaml

from repast4py import core, schedule, logging, parameters
from repast4py import context as ctx



def natural_sort(l): 
    convert = lambda text: int(text) if text.isdigit() else text.lower()
    alphanum_key = lambda key: [convert(c) for c in re.split('([0-9]+)', key)]
    return sorted(l, key=alphanum_key)

def clean_venue_list(vlist):
	vlist_remove_duplicates = list(set(vlist))
	vlist_new = natural_sort(vlist_remove_duplicates)	
	return vlist_new


model = None

# @dataclass 
# class Counts:
#     """Dataclass used by repast4py aggregate logging to record
#     the number of egos in each demographic group after each tick.
#     """
#     egos: int=0
#     # blackNH20under: int = 0
#     # blackNH21over: int = 0
#     # whiteNH20under: int = 0
#     # whiteNH21over: int = 0
#     # otherNH20under: int = 0
#     # otherNH21over: int = 0
#     # latinx20under: int = 0
#     # latinx21over: int = 0

class Ego(core.Agent):
    """The Synthetic Ego Agent

    Args:
        a_id: a integer that uniquely identifies this Ego on its
              starting rank
        rank: the starting MPI rank of this Ego.
        type: since there is only one type of Agent, we default the TYPE to 0
        age: age of the agent, where age is year plus number of days (where each day is 1/365) -- NOTE: is updated EACH timestep
        raceethnicity: raceethnicity group of agent -- NOTE: will NOT change
        agegroup: age group of agent -- NOTE: this can change as ego ages into the older age group
        eego_venues: the empirical ego used to assigne venue attendance -- NOTE: can change based on age group change
        eego_relationship: the empirical ego used to assign appuse when ego agent is in a relationship - NOTE: can change based on age group change
        eego_norelationship: the empirical ego used to assign appuse when ego agent is NOT in a relationship - NOTE: can change based on age group change
        relationshipstatus: relationship status of ego agent -- NOTE: is updated EACH time step

    """

    TYPE = 0

    def __init__(self, ego_id: int, rank: int):
        super().__init__(id=ego_id, type=Ego.TYPE, rank=rank)
        self.egoid = 's' + str(ego_id).zfill(5)
        self.age = 16.0 #0/365
        self.agegroup = '16to20' #16to20, 21to20 
        self.raceethnicity = 'blackNH' #blackNH, whiteNH, otherNH, hispanic
        self.democode = 1
        self.hivstatus = 0
        self.eego_venues = 'e001'
        self.eego_relationship = 'e001'
        self.eego_norelationship = 'e001'
        self.relationshipstatus = 0
        self.apps_rel = 's' + str(ego_id).zfill(5)
        self.apps_norel = 's' + str(ego_id).zfill(5)
        self.venues_attended = 's' + str(ego_id).zfill(5)
        self.apps_used = 's' + str(ego_id).zfill(5)

    def save(self) -> Tuple:
        """Saves the state of this Ego as a Tuple.

        Returns:
            The saved state of this ego.
        """
        return (self.uid, 
                self.egoid, self.age, self.agegroup, self.raceethnicity, self.democode, self.hivstatus,
                self.relationshipstatus, self.eego_venues, self.eego_relationship, self.eego_norelationship,
                self.apps_rel, self.apps_norel, 
                self.venues_attended, self.apps_used)

    # def step(self):



agent_cache = {}


def restore_agent(agent_data: Tuple):
    """Creates an agent from the specified agent_data.

    This is used to re-create agents when they have moved from one MPI rank to another.
    The tuple returned by the agent's save() method is moved between ranks, and restore_agent
    is called for each tuple in order to create the agent on that rank. Here we also use
    a cache to cache any agents already created on this rank, and only update their state
    rather than creating from scratch.

    Args:
        agent_data: the data to create the agent from. This is the tuple returned from the agent's save() method
                    where the first element is the agent id tuple, and any remaining arguments encapsulate
                    agent state.
    """
    uid = agent_data[0]
    # 0 is id, 1 is type, 2 is rank
    if uid in agent_cache:
        sego = agent_cache[uid]
    else:
        sego = Ego(uid[0], uid[2])
        agent_cache[uid] = sego

    # restore the agent state from the agent_data tuple
    sego.egoid = agent_data[1]
    sego.age = agent_data[2]
    sego.agegroup = agent_data[3]
    sego.raceethnicity = agent_data[4]
    sego.democode = agent_data[5]
    sego.hivstatus = agent_data[6]
    sego.relationshipstatus = agent_data[7]
    sego.eego_venues = agent_data[8]
    sego.eego_relationship = agent_data[9]
    sego.eego_norelationship = agent_data[10]
    sego.apps_rel = agent_data[11]
    sego.apps_norel = agent_data[12]
    sego.venues_attended = agent_data[13]
    sego.apps_used = agent_data[14]
    return sego

        

class Model:
    """
    The Model class encapsulates the simulation, and is
    responsible for initialization (scheduling events, creating agents,
    and the grid the agents inhabit), and the overall iterating
    behavior of the model.

    Args:
        comm: the mpi communicator over which the model is distributed.
        params: the simulation input parameters
    """

    def __init__(self, comm: MPI.Intracomm, params: Dict):
        # create the context to hold the agents and manage cross process
        # synchronization
        self.comm = comm
        self.context = ctx.SharedContext(comm)
        self.rank = self.comm.Get_rank()
        
        # create the schedule
        self.runner = schedule.init_schedule_runner(comm)
        self.runner.schedule_repeating_event(1, 1, self.step)
        self.runner.schedule_repeating_event(1.1, 1, self.log_agents)
        self.runner.schedule_stop(params['stop.at'])
        self.runner.schedule_end_event(self.at_end)

        # initialize Tabular logging 
        self.agent_logger = logging.TabularLogger(comm, params['agent_log_file'], ['tick', 'agent_id', 'agent_uid_rank', 'ego_id', 'age', 'age_group', 'race_ethnicity', 'hiv_status', 'venues_attended', 'apps_used'])

        print(MPI.Comm.Get_size(self.comm))

        sego_datafile = params['synthpop.ego.file']
        segodf = pd.read_csv(sego_datafile)
        segodf['appslist_rel'].fillna(segodf['egoid'], inplace=True)
        segodf['appslist_norel'].fillna(segodf['egoid'], inplace=True)

        self.egoidcounter = 1
        for index, row in segodf.iterrows():
            sego = Ego(row['numeric_id'], self.rank)
            sego.egoid = row['egoid']
            sego.age = row['age']
            # print(sego.age)
            sego.agegroup = row['agegroup']
            sego.raceethnicity = row['race_ethnicity']
            sego.democode = row['demographic_bucket']
            sego.hivstatus = row['hiv_status']
            sego.eego_venues = row['assigned_empego_for_venues']
            sego.relationshipstatus = int(row['any_serious'])
            sego.eego_relationship = row['assigned_empego_rel']
            sego.eego_norelationship = row['assigned_empego_norel']
            sego.apps_rel = row['appslist_rel']
            sego.apps_norel = row['appslist_norel']        
            sego.venues_attended = row['egoid']
            sego.apps_used = row['egoid']
            self.context.add(sego)
            self.egoidcounter += 1


        # create an object for empirical egos and their demo buckets
        self.empop_demo_buckets =  {key: value.split('|') for key, value in params['empop.demo.buckets'].items()}

        # create an object for empirical egos and their venue assignment
        self.empop_venue_attendance_dict = params['empop.venue.attendance']

        # create an object for empirical egos and their appslist 
        self.empop_appuse_dict = params['empop.app.use']
        # print(self.empop_appuse_dict)

        # create an object for empirical egos and their relationship status within demo buckets   
        self.empop_demo_rel_buckets = {outer_key: {inner_key: inner_value.split('|') if isinstance(inner_value, str) else inner_value for inner_key, inner_value in outer_value.items()} for outer_key, outer_value in params['empop.demo.rel.buckets'].items()}

        # create an object that is the apps and their app type
        self.venue_types = {key: value.split('|') for key, value in params['venue.types'].items()}

        # create an object that is the venues and their venue type
        self.app_types = {key: value.split('|') for key, value in params['app.types'].items()}


    def step(self):
        
        tick = self.runner.schedule.tick
        print(f'Week {tick} in simulation')
        self.context.synchronize(restore_agent)

        egos_over_thirty = []
        for sego in self.context.agents(Ego.TYPE):
            # sego.step()
            ################
            # age forward #
            ############### 
            sego.age += 7/365


            #############################################################
            # check if ego has aged out of the population, 
            # and if so, remove the agent 
            # and after removing the agent, create a new agent of the same raceethnicity, 
            # but of age 16 to enter 
            #############################################################
            # if sego.age > 29:
                # get race/ethnicity of agent 
                # remove agent


                # get demographics for new agent
            if sego.age >= 30:
                # print(f'{sego.egoid} is age {sego.age} and is leaving the model.')
                # # model.add_agent((len(self.context.agents())+1), random.choice(['blackNH', 'whiteNH', 'otherNH', 'hispanic']))
                # model.add_agent(self.egoidcounter, sego.raceethnicity)
                # model.remove_agent(sego)
                egos_over_thirty.append(sego)
            

            #############################################################
            # check if ego has aged enough to switch demographic groups 
            # if so, reassign demographic group and new ego assignments
            #############################################################
            if (sego.age >= 21) and (sego.agegroup == '16to20'):
                # update ego agegroup
                sego.agegroup = '21to29'

                # update ego demogroup
                if sego.raceethnicity == 'whiteNH':
                    sego.democode = 2
                elif sego.raceethnicity == 'blackNH':
                    sego.democode = 4
                elif sego.raceethnicity == 'hispanic':
                    sego.democode = 6
                else:
                    assert (sego.raceethnicity == 'otherNH')
                    sego.democode = 8
    
                # update empirical ego for venues
                sego.eego_venues = random.choice(self.empop_demo_buckets[sego.democode])

                # update empirical ego for rel
                sego.eego_relationship = random.choice(self.empop_demo_rel_buckets[sego.democode]['rel'])
                if sego.eego_relationship in self.empop_appuse_dict.keys():
                    sego.apps_rel = self.empop_appuse_dict[sego.eego_relationship]
                else:
                    sego.apps_rel = sego.egoid

                # update empirical ego for no rel  
                sego.eego_norelationship = random.choice(self.empop_demo_rel_buckets[sego.democode]['no_rel'])
                if sego.eego_norelationship in self.empop_appuse_dict.keys():
                    sego.apps_norel = self.empop_appuse_dict[sego.eego_norelationship]
                else:
                    sego.apps_norel = sego.egoid


            ################
            # attend venues 
            ################
            _sego_venues_dict = self.empop_venue_attendance_dict[sego.eego_venues]
            
            _venues_attended = []
            for thisvenue, thisattendancefreq in _sego_venues_dict.items():
                for day in range(1,8):
                    if random.random() <= thisattendancefreq:
                        _venues_attended.append(thisvenue)
            
            if not _venues_attended:
                sego.venues_attended = sego.egoid
            else:
                assert(len(_venues_attended) >= 1)
                sego.venues_attended = '|'.join(clean_venue_list(_venues_attended))
            
            
            ###########
            # use apps 
            ###########
            if sego.relationshipstatus == 0:
                sego.apps_used = sego.apps_norel
            else:
                assert(sego.relationshipstatus == 1) 
                sego.apps_used = sego.apps_rel

        for sego in egos_over_thirty:
            # print(f'{sego.egoid} is aged {sego.age}, {sego.raceethnicity} and is leaving the model.')
            # model.add_agent((len(self.context.agents())+1), random.choice(['blackNH', 'whiteNH', 'otherNH', 'hispanic']))
            model.add_agent(self.egoidcounter, sego.raceethnicity)
            model.remove_agent(sego)
            print(len(list(self.context.agents(Ego.TYPE))))            
            print("")


    def log_agents(self):
        tick = self.runner.schedule.tick 
        for sego in self.context.agents():
            self.agent_logger.log_row(tick, sego.id, sego.uid_rank, sego.egoid, sego.age, sego.agegroup, sego.raceethnicity, sego.hivstatus, sego.venues_attended, sego.apps_used)

        self.agent_logger.write()

    def remove_agent(self, agent):
        print(f'{agent.egoid} is aged {agent.age}, {agent.raceethnicity} and is leaving the model.')
        self.context.remove(agent)

    def add_agent(self, agentid, agentraceethnicity):
        sego = Ego(agentid, self.rank)
        sego.egoid = 's' + str(agentid).zfill(5)
        sego.age = 16.0
        sego.agegroup = '16to20'
        sego.hivstatus = 0
        sego.raceethnicity = agentraceethnicity
        #
        if agentraceethnicity == 'whiteNH':
            sego.democode = 1
        elif agentraceethnicity == 'blackNH':
            sego.democode = 3
        elif agentraceethnicity == 'hispanic':
            sego.democode = 5
        else:
            assert (agentraceethnicity == 'otherNH')
            sego.democode = 7
        #
        ##################################
        # assign empirical egos for venues 
        ##################################
        sego.eego_venues = random.choice(self.empop_demo_buckets[sego.democode])
        #
        ##########################################################
        # assign empirical egos for appuse and relationship status
        ##########################################################
        eego4relationshipstatus = random.choice(self.empop_demo_rel_buckets[sego.democode]['rel'] + self.empop_demo_rel_buckets[sego.democode]['no_rel'])
        if eego4relationshipstatus in self.empop_demo_rel_buckets[sego.democode]['rel']:
            sego.relationshipstatus = 1
            sego.eego_relationship = eego4relationshipstatus
            sego.eego_norelationship = random.choice(self.empop_demo_rel_buckets[sego.democode]['no_rel'])
        else:
            assert(eego4relationshipstatus in self.empop_demo_rel_buckets[sego.democode]['no_rel'])
            sego.relationshipstatus = 0
            sego.eego_relationship = random.choice(self.empop_demo_rel_buckets[sego.democode]['rel'])
            sego.eego_norelationship = eego4relationshipstatus 
        # update empirical ego for rel/no_rel appuse 
        if sego.eego_relationship in self.empop_appuse_dict.keys():
            sego.apps_rel = self.empop_appuse_dict[sego.eego_relationship]
        else:
            sego.apps_rel = sego.egoid
        if sego.eego_norelationship in self.empop_appuse_dict.keys():
            sego.apps_norel = self.empop_appuse_dict[sego.eego_norelationship]
        else:
            sego.apps_norel = sego.egoid
        #
        #########################################
        # have new ego attend venues and use apps
        #########################################
        # venues
        _sego_venues_dict = self.empop_venue_attendance_dict[sego.eego_venues]
        _venues_attended = []
        for thisvenue, thisattendancefreq in _sego_venues_dict.items():
            for day in range(1,8):
                if random.random() <= thisattendancefreq:
                    _venues_attended.append(thisvenue)
        if not _venues_attended:
            sego.venues_attended = sego.egoid
        else:
            assert(len(_venues_attended) >= 1)
            sego.venues_attended = '|'.join(clean_venue_list(_venues_attended))                    
        # apps       
        if sego.relationshipstatus == 0:
            sego.apps_used = sego.apps_norel
        else:
            assert(sego.relationshipstatus == 1) 
            sego.apps_used = sego.apps_rel            
        #    
        ##########
        # add ego
        ##########
        print(f'{sego.egoid} is age {sego.age} and {sego.raceethnicity} and is entering the model')    
        self.context.add(sego)
        self.egoidcounter += 1

    def at_end(self):
        self.agent_logger.close()
        
    def run(self):
        self.runner.execute()


# def run(params: Dict):
#     global model
#     model = Model(MPI.COMM_WORLD, params)
#     model.run()

# def hello_world():
#     print("HELLO WORLD!!!!!")


def run(params: Dict):
    global model
    model = Model(MPI.COMM_WORLD, params)
    model.run()    

if __name__ == "__main__":
    parser = parameters.create_args_parser()
    args = parser.parse_args()
    params = parameters.init_params(args.parameters_file, args.parameters)
    run(params)


# ############### PREVIOUS ITERATION ####################


# @dataclass
# class AttendanceLog:
#     daily_attendance: int = 0

# def reset_attendance_dict(venuelist: list):
#     dailyattendancedict = {}
#     for venue in venuelist:
#         dailyattendancedict[venue] = []
#     ### this is when a demographic count for each venue was needed
#     # for venue in venuelist:
#     #     dailyattendancedict[venue] = {}
#     #     for x in range (1,17):
#     #         dailyattendancedict[venue][x] = 0
#     return dailyattendancedict



