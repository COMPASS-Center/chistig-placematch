import sys
sys.path.append('/projects/p32153/ChiSTIG_model/')
import os
import pandas as pd
import numpy as np
import yaml
from chistig import utilities
pd.set_option('display.float_format', lambda x: '%.2f' % x)

pd.options.mode.chained_assignment = None  # default='warn'


# 1 update/reformat target stats
def reformat_target_stats_csv(ts_orig, params_dict):
	ts = ts_orig.copy()

	ts.columns = (ts.columns.str.replace(", ", "_") .str.replace(" ", "-") .str.lower())
	ts['orig_ind'] = ts['ind']
	ts['ind'] = ts['ind'].astype(str).str.lower() 
	ts['ind'].replace({
			"prop met in person (any)":"prop-met-in-person_any",	
			"prop met in bar/club":"prop-met-in-person_bar-club",
			"prop met in bathhouse":"prop-met-in-person_bathhouse",
			"prop met other in-person":"prop-met-in-person_other",
			"prop met online hookup site":"prop-met-online_hookup-site",
			"prop met online soc network":"prop-met-online_soc-network",
			"prop met elsewhere":"prop-met-elsewhere"
		}, inplace=True)
	# The target stat is for cross-partnership type degree - so for instance, 'Mean degree | main degree 0' is the mean casual degree given that you have 0 main partners.
	ts['ind'].replace({
			"mean degree | casual degree 0" : "init-casual-degree-0",	
			"mean degree | casual degree 1" : "init-casual-degree-1",
			"mean degree | casual degree 2+" : "init-casual-degree-2+",
			"mean degree | main degree 0" : "init-main-degree-0",
			"mean degree | main degree 1 or 2" : "init-main-degree-1+",
			"mean 1-time | persistent degree 0": "init-persistent-degree-0",
			"mean 1-time | persistent degree 1": "init-persistent-degree-1",
			"mean 1-time | persistent degree 2": "init-persistent-degree-2",
			"mean 1-time | persistent degree 3+": "init-persistent-degree-3+"
		}, inplace=True)
	ts['ind'] = ts['ind'].str.replace('|','_').str.replace(" _ ", "_") \
		.str.replace("mean degree ", "mean-degree_").str.replace("nh","NH").str.replace("latinx","hispanic") \
		.str.replace('prop same', 'prop-same').str.replace('same age cat', 'same-age') \
		.str.replace('age ', '').str.replace('16-20', '16to20').str.replace('21-29', '21to29') \
		.str.replace(' ', '-')
	
	target_stats_row_rename = ts.set_index('orig_ind')['ind']
	ts.set_index('ind', inplace=True)
	ts.drop(columns=['orig_ind'], inplace=True)

	new_row = ts.loc['prop-met-in-person_bar-club'] + ts.loc['prop-met-in-person_bathhouse']
	new_row.name = 'prop-met-in-person_dating'
	ts = pd.concat([ts, pd.DataFrame(new_row).T], ignore_index=False)

	new_row = ts.loc['prop-met-online_hookup-site'] + ts.loc['prop-met-online_soc-network']
	new_row.name = 'prop-met-online'
	ts = pd.concat([ts, pd.DataFrame(new_row).T], ignore_index=False)

	tscolumns2keep = []
	for thisp in params_dict['partnership.types']:
		tscolumns2keep.append(f'{thisp}-partners_modeled-pop')
		tscolumns2keep.append(f'{thisp}-partners_modeled-pop_lower-bound')
		tscolumns2keep.append(f'{thisp}-partners_modeled-pop_upper-bound')
	ts = ts[tscolumns2keep]

	ts = ts.rename(index={'prop-same-age_under21': 'prop-same-age_16to20'})
	ts = ts.rename(index={'mean-degree_under21': 'mean-degree_16to20'})

	return ts


# 2 compute target values
def compute_target_values(tsdf, egos, params_dict):

	n_egos = len(egos)
	n_egos_raceeth = egos.groupby(['race_ethnicity']).size()
	n_egos_age = egos.groupby(['agegroup']).size()

	race_cats = params_dict['race.ethnicity.categories']
	age_cats = params_dict['age.categories']
	rel_cats = {
		'main' : ['0', '1', '2+'], 
		'casual': ['0', '1+'], 
		'one-time': ['0', '1', '2', '3+']
	}

	rel_var_name = {'main' : 'init_cas_cat', 'casual' : 'init_ser_cat', 'one-time' : 'init_pers_cat'}
	egos_rel = egos[['egoid'] + list(rel_var_name.values())]
	for ptype, rcol in rel_var_name.items():
		egos_rel[rcol] = egos_rel[rcol].astype('str')
	n_egos_reldeg = {}
	for ptype in params_dict['partnership.types']:
		n_egos_reldeg[ptype] = egos_rel.groupby([rel_var_name[ptype]]).size()
		n_egos_reldeg[ptype] = n_egos_reldeg[ptype].rename({x: f'{rel_var_name[ptype]}.{x}' for x in rel_cats[ptype]})

	ts_by_p = {}
	for ptype in params_dict['partnership.types']:
		ts_by_p[ptype] = tsdf[[f'{ptype}-partners_modeled-pop', f'{ptype}-partners_modeled-pop_lower-bound', f'{ptype}-partners_modeled-pop_upper-bound']]
		ts_by_p[ptype].rename(columns={
				f'{ptype}-partners_modeled-pop': 'mean',
				f'{ptype}-partners_modeled-pop_lower-bound': 'lower',
				f'{ptype}-partners_modeled-pop_upper-bound': 'upper',
			}, inplace=True)

	dfsall = []	
	dfs = {}
	for ptype in params_dict['partnership.types']:
		ts_mult = params_dict['nodefactor.multipliers'][ptype]
		df = ts_by_p[ptype].copy()
		dfs[ptype] = {}

		# mean-degree
		dfs[ptype]['mean-degree'] = ts_mult * (df.loc['mean-degree', :] * (n_egos / 2))
		dfs[ptype]['mean-degree'] = dfs[ptype]['mean-degree'].to_frame().T
		dfs[ptype]['mean-degree'] = dfs[ptype]['mean-degree'].rename(index={dfs[ptype]['mean-degree'].index[0]: 'edges'})
        # NOTE: ask Katie why we are dividing by 26 and not 52

		# concurrency
		dfs[ptype]['concurrency'] = df.loc['prop-concurrent', :] * n_egos
		dfs[ptype]['concurrency'] = dfs[ptype]['concurrency'].to_frame().T
		dfs[ptype]['concurrency'] = dfs[ptype]['concurrency'].rename(index={dfs[ptype]['concurrency'].index[0]: 'concurrent'})

		# venue attendance 
		venues_rename_dict = {
			'prop-met-in-person_any': 'fuzzynodematch.venues_all.TRUE',
			'prop-met-in-person_dating': 'fuzzynodematch.venues_dating.TRUE',
			'prop-met-in-person_other': 'fuzzynodematch.venues_nondating.TRUE',
			}
		## NOTE: by using the 'prop-met-in-person_other' category, it provides a fix on the upper bound for the "venues_nondating" so that I no longer get values less than the lower bound (which is what was happening when I did: "prop-met-in-person_non-dating = prop-met-in-person_any - prop-met-in-person_dating")
		dfs[ptype]['venue-attendance'] = df.loc[list(venues_rename_dict.keys()), :].mul(dfs[ptype]['mean-degree'].iloc[0])
		dfs[ptype]['venue-attendance'] = dfs[ptype]['venue-attendance'].rename(index=venues_rename_dict)

		# app use  
		appuse_rename_dict = {
			'prop-met-online': 'fuzzynodematch.apps_all.TRUE', 
			'prop-met-online_hookup-site':'fuzzynodematch.apps_dating.TRUE', 
			'prop-met-online_soc-network':'fuzzynodematch.apps_nondating.TRUE'
			}
		dfs[ptype]['app-use'] = df.loc[list(appuse_rename_dict.keys()), :].mul(dfs[ptype]['mean-degree'].iloc[0])
		dfs[ptype]['app-use'] = dfs[ptype]['app-use'].rename(index=appuse_rename_dict)

		# nodefactor by race 
		dfs[ptype]['nodefactor-by-race'] = ts_mult * (df.loc[['mean-degree_' + str(x) for x in race_cats], :])
		dfs[ptype]['nodefactor-by-race'].rename(index={'mean-degree_' + str(x): str(x) for x in race_cats}, inplace=True)
		dfs[ptype]['nodefactor-by-race'] = dfs[ptype]['nodefactor-by-race'].mul(n_egos_raceeth, axis=0)

		# nodefactor by age
		dfs[ptype]['nodefactor-by-age'] = ts_mult * (df.loc[['mean-degree_' + str(x) for x in age_cats], :])
		dfs[ptype]['nodefactor-by-age'].rename(index={'mean-degree_' + str(x): str(x) for x in age_cats}, inplace=True)
		dfs[ptype]['nodefactor-by-age'] = dfs[ptype]['nodefactor-by-age'].mul(n_egos_age, axis=0)

		# homophily by race 
		df_prop_same_raceeth = df.loc[['prop-same-race_' + str(x) for x in race_cats], :]
		df_prop_same_raceeth.rename(index={'prop-same-race_' + str(x): x for x in race_cats}, inplace=True)
		homophily_by_race = (dfs[ptype]['nodefactor-by-race'] / 2) * df_prop_same_raceeth

		dfs[ptype]['homophily-by-race'] = {}
		dfs[ptype]['homophily-by-race']['uniform'] = homophily_by_race.sum(axis=0)
		dfs[ptype]['homophily-by-race']['uniform'] = dfs[ptype]['homophily-by-race']['uniform'].to_frame().T

		dfs[ptype]['homophily-by-race']['differential_one-level'] = homophily_by_race.loc[['blackNH'],:]
		dfs[ptype]['homophily-by-race']['differential_two-levels'] = homophily_by_race.loc[['blackNH', 'whiteNH'],:]
		dfs[ptype]['homophily-by-race']['differential_three-levels'] = homophily_by_race.loc[['blackNH', 'hispanic', 'whiteNH'],:]
		dfs[ptype]['homophily-by-race']['differential_four-levels'] = homophily_by_race.loc[['blackNH', 'hispanic', 'otherNH', 'whiteNH'],:]

		# homophily by age
		df_prop_same_age = df.loc[['prop-same-age_' + str(x) for x in age_cats], :]
		df_prop_same_age.rename(index={'prop-same-age_' + str(x): x for x in age_cats}, inplace=True)
		homophily_by_age = (dfs[ptype]['nodefactor-by-age'] / 2) * df_prop_same_age

		dfs[ptype]['homophily-by-age'] = {}
		dfs[ptype]['homophily-by-age']['uniform'] = homophily_by_age.sum(axis=0)
		dfs[ptype]['homophily-by-age']['uniform'] = dfs[ptype]['homophily-by-age']['uniform'].to_frame().T

		dfs[ptype]['homophily-by-age']['one-level'] = homophily_by_age.loc[['21to29'],:]
		dfs[ptype]['homophily-by-age']['differential'] = homophily_by_age.loc[['21to29', '16to20'],:]

		# nodefactor by cross partnership degree
		rel_targval_index = {'main' : 'init-casual-degree', 'casual' : 'init-main-degree', 'one-time' : 'init-persistent-degree'}
		dfs[ptype]['nodefactor-by-rel-deg'] = ts_mult * (df.loc[[rel_targval_index[ptype] + '-' + str(x) for x in rel_cats[ptype]], :])
		dfs[ptype]['nodefactor-by-rel-deg'].rename(index={f'{rel_targval_index[ptype]}-{x}': f'{rel_var_name[ptype]}.{x}' for x in rel_cats[ptype]}, inplace=True)
		dfs[ptype]['nodefactor-by-rel-deg'] = dfs[ptype]['nodefactor-by-rel-deg'].mul(n_egos_reldeg[ptype], axis=0)

		# rename indices
		dfs[ptype]['nodefactor-by-race'] = dfs[ptype]['nodefactor-by-race'].rename(index=lambda x: 'nodefactor.race_ethnicity.' + x)
		dfs[ptype]['nodefactor-by-age'] = dfs[ptype]['nodefactor-by-age'].rename(index=lambda x: 'nodefactor.age.' + x)

		dfs[ptype]['homophily-by-race']['uniform'] = dfs[ptype]['homophily-by-race']['uniform'].rename(index={dfs[ptype]['homophily-by-race']['uniform'].index[0]: 'nodematch.race_ethnicity'})
		dfs[ptype]['homophily-by-race']['differential_four-levels'] = dfs[ptype]['homophily-by-race']['differential_four-levels'].rename(index=lambda x: 'nodematch.race_ethnicity.' + x)

		dfs[ptype]['homophily-by-age']['differential'] = dfs[ptype]['homophily-by-age']['differential'].rename(index=lambda x: 'nodematch.age.' + x)
		dfs[ptype]['homophily-by-age']['uniform'] = dfs[ptype]['homophily-by-age']['uniform'].rename(index={dfs[ptype]['homophily-by-age']['uniform'].index[0]: 'nodematch.age'})

		dfs[ptype]['nodefactor-by-rel-deg'] = dfs[ptype]['nodefactor-by-rel-deg'].rename(index=lambda x: 'nodefactor.' + x)

		dfs2keep = [dfs[ptype]['mean-degree'], \
						dfs[ptype]['concurrency'], 
							dfs[ptype]['nodefactor-by-race'], 
								dfs[ptype]['nodefactor-by-age'], \
									dfs[ptype]['homophily-by-race']['uniform'], \
										dfs[ptype]['homophily-by-race']['differential_four-levels'], \
											dfs[ptype]['homophily-by-age']['uniform'], \
												dfs[ptype]['homophily-by-age']['differential'], \
													dfs[ptype]['nodefactor-by-rel-deg'], \
														dfs[ptype]['venue-attendance'], \
															dfs[ptype]['app-use']]
		dfall = pd.concat(dfs2keep)
		dfall = dfall.add_suffix(f'_{ptype}')
		dfsall.append(dfall)

	df = pd.concat(dfsall, axis=1)
	df = df.reindex(params_dict['term.order'])

	return df




if __name__ == "__main__":

    this_path = os.path.abspath(__file__)
    # package_path = os.path.normpath(os.path.join(script_path, relative_path))

    #
    if len(sys.argv) >= 2:
        yaml_fname = sys.argv[1]
        # Read and parse the YAML file into a dictionary
        params = utilities.parse_params(yaml_fname, '')

    tspath =  os.path.normpath(os.path.join(this_path, params['target.stats.path'])) 
    tsdf = pd.read_csv(f"{tspath}/{params['target.stats.file']}")
    ts = reformat_target_stats_csv(tsdf, params)

    spop_version = str(params['synthpop.version']).split('.')[0]
    egospath = os.path.normpath(os.path.join(this_path, params['synthpop.path'], f'v{spop_version}'))
    egosdf = pd.read_csv(f"{egospath}/{params['synthpop.ego.file']}")
    
    tv = compute_target_values(ts, egosdf, params)
    print(tv.head(50))
    tv.to_csv(f"../params/target_values_v{str(params['synthpop.version']).replace('.', '_')}.csv", index=True)









    
