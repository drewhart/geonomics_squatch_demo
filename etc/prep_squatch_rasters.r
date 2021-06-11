library(raster)

# params
start_yr = 1900 # year when gnx sim will start
NAflag = -9999

# load the squatch SDM
sdm = raster('./lyrs/Bigfoot-all.asc')
crs(sdm) = crs('+init=epsg:4326')

# set anything < 0.5 = NA
sdm[sdm<0.5] = NA

# make square
sdm = sdm[70:260, 70:260, drop=F]

# load historical bioclim vars
# response curves:
        # bio8: mean tmp wettest quarter: gradual increase from min to 32.85 deg C,
              # then sharp decrease
        # bio19: ppt coldest quarter: sharp increase in occurence prob at 1456mm
bio8 = raster('./lyrs/hist/wc2.1_5m_bio_8.tif')
bio19 = raster('./lyrs/hist/wc2.1_5m_bio_19.tif')

# no need to reproject, already lined up, just mask and crop
bio8 = mask(crop(bio8, sdm), sdm)
bio19 = mask(crop(bio19, sdm), sdm)

# write these three rasters out
writeRaster(sdm, './squatch_lyrs/squatch_sdm.tif', 'GTiff', overwrite=T, NAflag=NAflag)
writeRaster(bio8, './squatch_lyrs/squatch_bio8', 'GTiff', overwrite=T, NAflag=NAflag)
writeRaster(bio19, './squatch_lyrs/squatch_bio19', 'GTiff', overwrite=T, NAflag=NAflag)

# make a linear model for hokey future projection
mod_df = data.frame(sdm=sdm[,], bio8=bio8[,], bio19=bio19[,])
mod = lm(sdm ~ bio19 + bio8, data=mod_df)

# make the future rasters
dirs = c('2021-2040', '2041-2060', '2061-2080', '2081-2100')

# keep all, to inspect min and max vals later
sdm_stack = stack(sdm)
bio8_stack = stack(bio8)
bio19_stack = stack(bio19)

for (dir in dirs){
    fn = grep('tif', list.files(paste0('./lyrs/', dir)), value=T)
    futbio = brick(paste0('./lyrs/', dir, '/', fn))
    futbio8 = futbio[[8]]
    futbio19 = futbio[[19]]
    # no need to reproject, again
    # just crop, mask
    futbio8 = mask(crop(futbio8, sdm), sdm)
    futbio19 = mask(crop(futbio19, sdm), sdm)
    # project the new SDM
    futstack = stack(futbio8, futbio19)
    names(futstack) = c('bio8', 'bio19')
    futsdm = raster::predict(futstack, mod)
    # write the lyrs out
    gnx_yr = as.numeric(strsplit(dir, '-')[[1]][1]) - start_yr
    writeRaster(futsdm, paste0('./squatch_lyrs/sdm/',
                            as.character(gnx_yr),
                            '_squatch_sdm.tif'),
                'GTiff', overwrite=T, NAflag=NAflag)
    writeRaster(futbio8, paste0('./squatch_lyrs/bio8/',
                            as.character(gnx_yr),
                            '_squatch_bio8'),
                'GTiff', overwrite=T, NAflag=NAflag)
    writeRaster(futbio19, paste0('./squatch_lyrs/bio19/',
                            as.character(gnx_yr),
                            '_squatch_bio19'),
                'GTiff', overwrite=T, NAflag=NAflag)

    # add to the stacks
    sdm_stack = stack(sdm_stack, futsdm)
    bio8_stack = stack(bio8_stack, futbio8)
    bio19_stack = stack(bio19_stack, futbio19)
}
