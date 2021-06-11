import geonomics as gnx
mod = gnx.make_model('squatch_params.py')
mod.walk(100000, 'burn')
mod.walk(10)
