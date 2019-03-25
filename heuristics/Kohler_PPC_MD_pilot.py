import os
import numpy
from cfmm_base import infotodict as cfmminfodict
from cfmm_base import create_key

def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where

    allowed template fields - follow python string module:

    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """

    # call cfmm for general labelling and get dictionary
    info = cfmminfodict(seqinfo)



    task_localizer = create_key('{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-localizer_run-{item:02d}_bold')
    task_lifetime = create_key('{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-lifetime_run-{item:02d}_bold')
    task_localizerReverse = create_key('{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-localizerReverse_run-{item:02d}_bold')
	task_localizerTE25 = create_key('{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-localizerTE25_run-{item:02d}_bold')


    #discarded = create_key('sourcedata/discarded_bold/{bids_subject_session_dir}/func/{bids_subject_session_prefix}_task-{task}_run-{item:02d}_bold')



    info[task_localizer]=[]
    info[task_lifetime]=[]
    info[task_localizerreverse]=[]
	info[task_localizerTE25]=[]
    #info[discarded]=[]

    for idx, s in enumerate(seqinfo):
       
        if ('bold' in s.protocol_name or 'tasking_state' in s.series_description or 'mbep2d' in (s.series_description).strip() or 'ep_bold' in (s.series_description).strip() and not ('diff' in s.protocol_name or 'DWI' in s.series_description )):
            
            if ('SBRef' in (s.series_description).strip()):
                print('skipping sbref')


            else:

                #check what task it is
                if ('PRC_localizer' in (s.series_description).strip().lower() and 'reverse' not in (s.series_description).strip().lower() and 'TE25' not in (s.series_description).strip().lower()):
                    taskname='PRClocalizer-original'
                    #taskvols=40

                   # if (s.dim4 < taskvols):
                      #  info[discarded].append({'item': s.series_id,'task': taskname})
                   # elif (s.dim4 == taskvols): 
                     #   info[task_soundcheck].append({'item': s.series_id,'task': taskname})


                elif ('PRC_localizer' in (s.series_description).strip().lower() and 'reverse' in (s.series_description).strip().lower()):
                    taskname='PRClocalizer-revangle'
                    #taskvols=320

                    #if (s.dim4 < taskvols):
                        #info[discarded].append({'item': s.series_id,'task': taskname})
                   # elif (s.dim4 == taskvols): 
                        #info[task_intact].append({'item': s.series_id,'task': taskname})


                elif ('PRC_localizer' in (s.series_description).strip().lower() and 'TE25' in (s.series_description).strip().lower()):
                    taskname='PRClocalizer-shortTE'
                   # taskvols=320


                   # if (s.dim4 < taskvols):
                    #    info[discarded].append({'item': s.series_id,'task': taskname})
                   # elif (s.dim4 == taskvols): 
                     #   info[task_scrambled].append({'item': s.series_id,'task': taskname})
					 
				elif ('lifetime' in (s.series_description).strip().lower()):
					taskname='lifetime'

                else:
                    continue

 
                  
    return info
