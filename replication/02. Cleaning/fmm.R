# Set Up
library(sf)
library(sp)
library(raster)
setwd("C:/Users/JianingShao/OneDrive - London School of Economics/Thesis/GIS_output")

# Import data
ports <- st_read("ports.shp")
amc_micro <- st_read("amc_micro.shp")
amc_meso <- st_read("amc_meso.shp")
highway_2010 <- raster("highway2010")
highway_2000 <- raster("highway_2000")
highway_1990 <- raster("highway_1990")
highway_1980 <- raster("highway_1980")
highway_1970 <- raster("highway_1970")
highway_1960 <- raster("highway_1960")
pnv <- raster("pnv")


# Convert to spatial objects
ports_sp <- as(ports, "Spatial")
amc_micro_sp <- as(amc_micro, "Spatial")
amc_meso_sp <- as(amc_meso, "Spatial")
seeds.df <- data.frame(incept=rep(0, 13), speed=rep(0.1, 13))
seeds <- SpatialPointsDataFrame(ports_sp, seeds.df)

# Highway2010 domain
fm_2010 <- spFastMarch(highway_2010, seeds)
plot(fm_2010$arrival.time, main='arrival time')
amc_micro_index <- cellFromXY(fm_2010$arrival.time, coordinates(amc_micro_sp))
amc_meso_index <- cellFromXY(fm_2010$arrival.time, coordinates(amc_meso_sp))
arrival_time_2010_amc_micro <- extract(fm_2010$arrival.time, amc_micro_index)
arrival_time_2010_amc_meso <- extract(fm_2010$arrival.time, amc_meso_index)

# Highway2000 domain
fm_2000 <- spFastMarch(highway_2000, seeds)
plot(fm_2000$arrival.time, main='arrival time')
amc_micro_index <- cellFromXY(fm_2000$arrival.time, coordinates(amc_micro_sp))
amc_meso_index <- cellFromXY(fm_2000$arrival.time, coordinates(amc_meso_sp))
arrival_time_2000_amc_micro <- extract(fm_2000$arrival.time, amc_micro_index)
arrival_time_2000_amc_meso <- extract(fm_2000$arrival.time, amc_meso_index)

# Highway1990 domain
fm_1990 <- spFastMarch(highway_1990, seeds)
plot(fm_1990$arrival.time, main='arrival time')
amc_micro_index <- cellFromXY(fm_1990$arrival.time, coordinates(amc_micro_sp))
amc_meso_index <- cellFromXY(fm_1990$arrival.time, coordinates(amc_meso_sp))
arrival_time_1990_amc_micro <- extract(fm_1990$arrival.time, amc_micro_index)
arrival_time_1990_amc_meso <- extract(fm_1990$arrival.time, amc_meso_index)

# Highway1980 domain
fm_1980 <- spFastMarch(highway_1980, seeds)
plot(fm_1980$arrival.time, main='arrival time')
amc_micro_index <- cellFromXY(fm_1980$arrival.time, coordinates(amc_micro_sp))
amc_meso_index <- cellFromXY(fm_1980$arrival.time, coordinates(amc_meso_sp))
arrival_time_1980_amc_micro <- extract(fm_1980$arrival.time, amc_micro_index)
arrival_time_1980_amc_meso <- extract(fm_1980$arrival.time, amc_meso_index)

# Highway1970 domain
fm_1970 <- spFastMarch(highway_1970, seeds)
plot(fm_1970$arrival.time, main='arrival time')
amc_micro_index <- cellFromXY(fm_1970$arrival.time, coordinates(amc_micro_sp))
amc_meso_index <- cellFromXY(fm_1970$arrival.time, coordinates(amc_meso_sp))
arrival_time_1970_amc_micro <- extract(fm_1970$arrival.time, amc_micro_index)
arrival_time_1970_amc_meso <- extract(fm_1970$arrival.time, amc_meso_index)


# Highway1960 domain
fm_1960 <- spFastMarch(highway_1960, seeds)
plot(fm_1960$arrival.time, main='arrival time')
amc_micro_index <- cellFromXY(fm_1960$arrival.time, coordinates(amc_micro_sp))
amc_meso_index <- cellFromXY(fm_1960$arrival.time, coordinates(amc_meso_sp))
arrival_time_1960_amc_micro <- extract(fm_1960$arrival.time, amc_micro_index)
arrival_time_1960_amc_meso <- extract(fm_1960$arrival.time, amc_meso_index)


# PNV domain
fm_pnv <- spFastMarch(pnv, seeds)
plot(fm_pnv$arrival.time, main='arrival time')
amc_micro_index <- cellFromXY(fm_pnv$arrival.time, coordinates(amc_micro_sp))
amc_meso_index <- cellFromXY(fm_pnv$arrival.time, coordinates(amc_meso_sp))
arrival_time_pnv_amc_micro <- extract(fm_pnv$arrival.time, amc_micro_index)
arrival_time_pnv_amc_meso <- extract(fm_pnv$arrival.time, amc_meso_index)




fmm_amc_micro <- data.frame(amc_micro$MICRORREGI, arrival_time_2010_amc_micro, 
                            arrival_time_2000_amc_micro, arrival_time_1990_amc_micro, 
                            arrival_time_1980_amc_micro, arrival_time_1970_amc_micro, 
                            arrival_time_1960_amc_micro, arrival_time_pnv_amc_micro)
fmm_amc_meso <- data.frame(amc_meso$MESORREGI, arrival_time_2010_amc_meso, 
                           arrival_time_2000_amc_meso, arrival_time_1990_amc_meso, 
                           arrival_time_1980_amc_meso, arrival_time_1970_amc_meso,
                           arrival_time_1960_amc_meso, arrival_time_pnv_amc_meso)


write.csv(fmm_amc_micro, "C:/Users/JianingShao/OneDrive - London School of Economics/Thesis/build/input/fmm_amc_micro.csv")
write.csv(fmm_amc_meso, "C:/Users/JianingShao/OneDrive - London School of Economics/Thesis/build/input/fmm_amc_meso.csv")


