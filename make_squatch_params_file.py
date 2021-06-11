import geonomics as gnx
gnx.make_parameters_file('squatch_params.py',
                         layers=[{'type':'file', 'change':True}]*3,
                         species=[{'movement':True, 'movement_surface':True,
                                   'genomes':True, 'n_traits':2}],
                         data=False, stats=False)
