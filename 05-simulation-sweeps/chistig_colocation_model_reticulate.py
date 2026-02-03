import sys
import re
import math
import pandas as pd
import numpy as np
from typing import Dict, Tuple
from mpi4py import MPI
from dataclasses import dataclass
import yaml
import time

from repast4py import core, schedule, logging, parameters, random 
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
        relationshipstatus: relationship status of ego agent -- NOTE: is updated EACH time step
        hiv_status: the hiv status of the agent 

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
        self.relationshipstatus = 0
        self.eego = 'e001'
        self.venues_attended = 's' + str(ego_id).zfill(5)
        self.apps_used = 's' + str(ego_id).zfill(5)

    def save(self) -> Tuple:
        """Saves the state of this Ego as a Tuple.

        Returns:
            The saved state of this ego.
        """
        return (self.uid,
                self.egoid, self.age, self.agegroup, self.raceethnicity, self.democode, self.hivstatus, self.relationshipstatus,
                self.eego, self.venues_attended, self.apps_used)


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
    sego.eego = agent_data[8]
    sego.venues_attended = agent_data[9]
    sego.apps_used = agent_data[10]
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
        # self.runner.schedule_repeating_event(1.1, 1, self.log_agents)
        # self.runner.schedule_stop(params['stop.at'])
        # self.runner.schedule_end_event(self.at_end)


        # # Set seed from params, but before derived params are evaluated.
        # if 'random.seed' in params:
        #     random.init(int(params['random.seed']))
        # else:
        #     # repast4py should do this when random is imported
        #     # but for now do it explicitly here
        #     random.init(int(time.time()))

        # initialize Tabular logging 
        self.agent_logger = logging.TabularLogger(comm, params['agent.log.file'], ['tick', 'agent_id', 'agent_uid_rank', 'ego_id', 'age', 'age_group', 'race_ethnicity', 'hiv_status', 'relationship_status', 'assigned_eego', 'venues_attended', 'apps_used'])

        # print(MPI.Comm.Get_size(self.comm))

        sego_datafile = params['synthpop.ego.file']
        segodf = pd.read_csv(sego_datafile)

        self.egoidcounter = 1
        for index, row in segodf.iterrows():
            sego = Ego(row['numeric_id'], self.rank)
            sego.egoid = row['egoid']
            sego.age = row['age']
            sego.agegroup = row['agegroup']
            sego.raceethnicity = row['race_ethnicity']
            sego.democode = row['demographic_bucket']
            # sego.hivstatus = 0
            sego.hivstatus = row['hiv_status']
            sego.relationshipstatus = int(row['any_serious'])
            sego.eego = row['assigned_empego']
            sego.venues_attended = row['egoid']
            sego.apps_used = row['egoid']
            self.context.add(sego)
            self.egoidcounter += 1


        # create an object for empirical egos and their demo buckets
        self.empop_demo_buckets = {key: value.split('|') for key, value in params['empop.demo.buckets'].items()}

        # create an object for empirical egos and their venue assignment
        self.empop_venue_attendance_dict = params['empop.venue.attendance']

        # create an object for empirical egos and their appslist 
        self.empop_appuse_dict = params['empop.app.use']

        # create an object for empirical egos and their relationship status within demo buckets   
        # self.empop_demo_rel_buckets = {outer_key: {inner_key: inner_value.split('|') if isinstance(inner_value, str) else inner_value for inner_key, inner_value in outer_value.items()} for outer_key, outer_value in params['empop.demo.rel.buckets'].items()}

        # create an object that is the venues and their venue type
        self.venue_types = {key: value.split('|') for key, value in params['venue.types'].items()}
        self.venues_dating = self.venue_types['bar-club'] + self.venue_types['bathhouse']
        self.venues_nondating = self.venue_types['arts-theatre'] + self.venue_types['communityorganization'] + self.venue_types['museum-library-attraction-casino'] + self.venue_types['park-neighborhood'] + self.venue_types['restaurant-coffeeshop'] + self.venue_types['school-college-university'] + self.venue_types['shopping'] + self.venue_types['somethingelse'] + self.venue_types['sports-gamingvenue']

        # create an object that is the apps and their app type
        self.app_types = {key: value.split('|') for key, value in params['app.types'].items()}
        self.apps_dating = self.app_types['classifiedandescort'] + self.app_types['hookup-datingapp']
        self.apps_nondating = self.app_types['socialnetwork']



    def step(self):
        tick = self.runner.schedule.tick
        print(f'\nAgents are attending venues and using apps for week {tick} in simulation...\n')
        # self.context.synchronize(restore_agent)

        for sego in self.context.agents(Ego.TYPE):
            ################
            # attend venues 
            ################
            _sego_venues_dict = self.empop_venue_attendance_dict[sego.eego]
            
            _venues_attended = []
            for thisvenue, thisattendancefreq in _sego_venues_dict.items():
                for day in range(1,8):
                    if random.default_rng.random() <= thisattendancefreq:
                        _venues_attended.append(thisvenue)
            
            if not _venues_attended:
                sego.venues_attended = sego.egoid
            else:
                assert(len(_venues_attended) >= 1)
                sego.venues_attended = '|'.join(clean_venue_list(_venues_attended))
            
            ###########
            # use apps
            ###########
            if sego.eego in self.empop_appuse_dict.keys():
                sego.apps_used = self.empop_appuse_dict[sego.eego]
            else:
                sego.apps_used = sego.egoid

        self.log_agents()


    def log_agents(self):
        tick = self.runner.schedule.tick
        if tick >= params['burnin.time.weeks']: 
            for sego in self.context.agents():
                self.agent_logger.log_row(tick, sego.id, sego.uid_rank, sego.egoid, sego.age, sego.agegroup, sego.raceethnicity, sego.hivstatus, sego.relationshipstatus, sego.eego, sego.venues_attended, sego.apps_used)
        self.agent_logger.write()

    def remove_agent(self, agent):
        print(f'{agent.egoid} is aged {agent.age}, {agent.raceethnicity} and is leaving the simulation.')
        self.context.remove(agent)

    def add_agent_from_epimodel(self, agentid, agentegoid, agentraceethnicity, agentdemocode):
        sego = Ego(agentid, self.rank)
        sego.egoid = agentegoid
        sego.age = 16.0
        sego.agegroup = '16to20'
        sego.hivstatus = 0
        sego.raceethnicity = agentraceethnicity
        sego.democode = agentdemocode
        sego.relationshipstatus = 0
        #
        ######################
        # assign empirical ego
        ######################
        sego.eego = random.default_rng.choice(self.empop_demo_buckets[str(sego.democode)])
        #
        #########################################
        # have new ego attend venues and use apps
        #########################################
        # venues
        _sego_venues_dict = self.empop_venue_attendance_dict[sego.eego]
        _venues_attended = []
        for thisvenue, thisattendancefreq in _sego_venues_dict.items():
            for day in range(1,8):
                if random.default_rng.random() <= thisattendancefreq:
                    _venues_attended.append(thisvenue)
        if not _venues_attended:
            sego.venues_attended = sego.egoid
        else:
            assert(len(_venues_attended) >= 1)
            sego.venues_attended = '|'.join(clean_venue_list(_venues_attended))                    
        # apps
        if sego.eego in self.empop_appuse_dict.keys():
            sego.apps_used = self.empop_appuse_dict[sego.eego]
        else:
            sego.apps_used = sego.egoid
        #    
        ##########
        # add ego
        ##########
        print(f'{sego.egoid} is age {sego.age} and {sego.raceethnicity} and is entering the model')    
        self.context.add(sego)

    def update_agent_agegroup_from_epimodel(self, egonumericid):
        thissego = self.context.agent((egonumericid, 0, 0))
        thissego.agegroup = '21to29'
        # update ego demogroup
        if thissego.raceethnicity == 'whiteNH':
            thissego.democode = 2
        elif thissego.raceethnicity == 'blackNH':
            thissego.democode = 4
        elif thissego.raceethnicity == 'hispanic':
            thissego.democode = 6
        else:
            assert (thissego.raceethnicity == 'otherNH')
            thissego.democode = 8        
        # update empirical ego
        thissego.eego = random.default_rng.choice(self.empop_demo_buckets[str(thissego.democode)])
        print(f'{thissego.egoid} is {thissego.age} and has aged to age group {thissego.agegroup}.')


    def update_egos_from_epimodel(self, activeegoslist, segos2egoiddict, segos2reldict, segos2hivdict, segos2agedict):
        egos2remove = []
        for sego in self.context.agents(Ego.TYPE):
            segonumericid = int(sego.id)
            if segonumericid in activeegoslist:
                assert(sego.egoid == segos2egoiddict[segonumericid])
                # update relationship status 
                sego.relationshipstatus = segos2reldict[segonumericid]
                # update hiv status
                if (sego.hivstatus == 0):
                    if segos2hivdict[segonumericid] == 1:
                        sego.hivstatus = 1
                        print(f'{sego.egoid} is {sego.raceethnicity}, aged {sego.age} in age group {sego.agegroup}, with relationship status of {sego.relationshipstatus} and is now HIV+.')
                else:
                    assert(sego.hivstatus == 1)
                    if segos2hivdict[segonumericid] == 0:
                        print(f"There is an error with the HIV status assignment for {sego.egoid} as an ego is switching from HIV+ to HIV-.")        
                # update age
                sego.age = segos2agedict[segonumericid]
            else:
                egos2remove.append(sego)
        print("\nAgents are being removed from the simulation...")
        for sego in egos2remove:
            model.remove_agent(sego)

    def attend_venues_for_epimodel(self, activeegoslist):
        egos2venues = []
        egos2venues_dating = []
        egos2venues_nondating = []
        for thisegonumericid in activeegoslist:   
            thissego = self.context.agent((int(thisegonumericid), 0, 0))
            egos2venues.append(thissego.venues_attended)
            if thissego.venues_attended == thissego.egoid:
                egos2venues_dating.append(thissego.venues_attended)
                egos2venues_nondating.append(thissego.venues_attended)
            else:
                _thisego2venues_list = thissego.venues_attended.split("|")
                _thisego2venues_list = clean_venue_list(_thisego2venues_list)
                _thisego2venues_list_dating = []
                _thisego2venues_list_nondating = []
                for thisvenue in _thisego2venues_list:
                    assert(len(thisvenue) > 1)
                    if thisvenue in self.venues_dating:
                        _thisego2venues_list_dating.append(thisvenue)
                    else:
                        assert(thisvenue in self.venues_nondating)
                        _thisego2venues_list_nondating.append(thisvenue)                    
                if len(_thisego2venues_list_dating) > 0:
                    _thisego2venues_list_dating = clean_venue_list(_thisego2venues_list_dating)
                else:
                    assert(len(_thisego2venues_list_dating) == 0)
                    _thisego2venues_list_dating.append(thissego.egoid)
                if len(_thisego2venues_list_nondating) > 0:
                    _thisego2venues_list_nondating = clean_venue_list(_thisego2venues_list_nondating)
                else:
                    assert(len(_thisego2venues_list_nondating) == 0)
                    _thisego2venues_list_nondating.append(thissego.egoid)                
                egos2venues_dating.append('|'.join(_thisego2venues_list_dating))
                egos2venues_nondating.append('|'.join(_thisego2venues_list_nondating))
        #
        egos2venues_df = pd.DataFrame({'numeric_id' : activeegoslist,
                            'venues_all' : egos2venues,
                            'venues_dating' : egos2venues_dating,
                            'venues_nondating' : egos2venues_nondating,
                        })
        return egos2venues_df
    
    def use_apps_for_epimodel(self, activeegoslist):
        egos2apps = []
        egos2apps_dating = []
        egos2apps_nondating = []
        for thisegonumericid in activeegoslist:
            thissego = self.context.agent((int(thisegonumericid), 0, 0))
            egos2apps.append(thissego.apps_used)
            if (thissego.apps_used == thissego.egoid):
                egos2apps_dating.append(thissego.apps_used)
                egos2apps_nondating.append(thissego.apps_used)
            else:
                _thisego2apps_list = thissego.apps_used.split("|")
                _thisego2apps_list = clean_venue_list(_thisego2apps_list)
                _thisego2apps_list_dating = []
                _thisego2apps_list_nondating = []
                for thisapp in _thisego2apps_list:
                    if thisapp in self.apps_dating:
                        _thisego2apps_list_dating.append(thisapp)
                    else:
                        assert(thisapp in self.apps_nondating)
                        _thisego2apps_list_nondating.append(thisapp)
                if len(_thisego2apps_list_dating) > 0:
                    _thisego2apps_list_dating = clean_venue_list(_thisego2apps_list_dating)
                else:  
                    assert(len(_thisego2apps_list_dating) == 0)
                    _thisego2apps_list_dating.append(thissego.egoid)   
                if len(_thisego2apps_list_nondating) > 0:
                    _thisego2apps_list_nondating = clean_venue_list(_thisego2apps_list_nondating)
                else:
                    assert(len(_thisego2apps_list_nondating) == 0)
                    _thisego2apps_list_nondating.append(thissego.egoid) 
                egos2apps_dating.append('|'.join(_thisego2apps_list_dating))
                egos2apps_nondating.append('|'.join(_thisego2apps_list_nondating))
        egos2apps_df = pd.DataFrame({
                            'numeric_id':activeegoslist,
                            'apps_all':egos2apps,
                            'apps_dating':egos2apps_dating,
                            'apps_nondating':egos2apps_nondating,
                        })
        return egos2apps_df

    def at_end(self):
        self.agent_logger.close()
        
    def run(self):
        pass
        # self.runner.execute()
        # print("hello again, but from model run!")

    def next_step(self):
        self.runner.schedule.execute()        


def run(params: Dict):
    global model
    model = Model(MPI.COMM_WORLD, params)


def set_random_seed(random_seed_str):
    random.init(int(random_seed_str))


def create_params(parameters_file):
    global params 
    params = parameters.init_params(parameters_file, '')
    return params

def hello_world():
    print("hello")

def next_step():
    model.next_step()

def read_data(passeddata):
    pass

def update_age_groups(newly21nodesdf):
    print("\nAgents who have aged to a new age group are being updated...")
    if len(newly21nodesdf) > 0:
        for index, row in newly21nodesdf.iterrows():
            model.update_agent_agegroup_from_epimodel(int(row['numeric.id']))
    else:
        pass

def update_egos(segosdf):
    print("")
    print("The ages, hiv status, and relationship status for the agents are being updated...")
    # this method will do the following:
    # - update the ages of all of the egos to match the Epimodel simulation
    # - update the HIV status of all the egos to match the Epimodel simulation
    # - update the relationship status of all the egos to match the Epimodel simulation
    # - remove all of the non-active egos from the colocation model (who are no longer in the Epimodel simulation)
    segosdf['numeric.id'] = segosdf['numeric.id'].astype(int)
    segosdf['hiv_status'] = segosdf['hiv_status'].astype(int)
    segosdf['rel_status'] = segosdf['rel_status'].astype(int)

    active_egos = segosdf['numeric.id'].to_list()
    segos2egoid_dict = segosdf.set_index('numeric.id')['egoid'].to_dict()
    segos2rel_dict = segosdf.set_index('numeric.id')['rel_status'].to_dict()
    segos2hiv_dict = segosdf.set_index('numeric.id')['hiv_status'].to_dict()
    segos2age_dict = segosdf.set_index('numeric.id')['age'].to_dict()
    model.update_egos_from_epimodel(active_egos, segos2egoid_dict, segos2rel_dict, segos2hiv_dict, segos2age_dict)


def obtain_venue_attendance(activesegosdf):
    activesegosdf['numeric.id'] = activesegosdf['numeric.id'].astype(int)
    active_egos = activesegosdf['numeric.id'].to_list()
    venues_df = model.attend_venues_for_epimodel(active_egos)
    return venues_df


def obtain_app_use(activesegosdf):
    activesegosdf['numeric.id'] = activesegosdf['numeric.id'].astype(int)
    active_egos = activesegosdf['numeric.id'].to_list()
    apps_df = model.use_apps_for_epimodel(active_egos)
    return apps_df


def add_agents_to_simulation(newnodesdf):
    print("\nNew agents are being added to the simulation...")
    if len(newnodesdf) > 0:
        for index, row in newnodesdf.iterrows():
            numericid = int(row['numeric.id'])
            egoid = row['egoid']
            if int(row['race_ethnicity']) == 1:
                raceethnicity = 'blackNH'
                democode = 3
            elif int(row['race_ethnicity']) == 2:
                raceethnicity = 'hispanic'
                democode = 5
            elif int(row['race_ethnicity']) == 3:
                raceethnicity = 'otherNH'
                democode = 7
            else:
                assert(int(row['race_ethnicity']) == 4)
                raceethnicity = 'whiteNH'
                democode = 1                 
            model.add_agent_from_epimodel(numericid, egoid, raceethnicity, democode)
    else:
        pass


def end_chistig():
    model.at_end()