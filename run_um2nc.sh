#!/bin/bash
#PBS -q normal
#PBS -l ncpus=8
#PBS -l mem=32GB
#PBS -l walltime=08:00:00
#PBS -l storage=gdata/hh5+gdata/access+gdata/ce10+scratch/ce10+gdata/vk83
#PBS -l wd
#PBS -l jobfs=10GB
#PBS -P ce10

# set -eu
module purge
module use /g/data/vk83/prerelease/modules
module load payu/dev

CYCLPATH=/scratch/ce10/mjl561/cylc-run/rns_ostia/share/cycle

# get list of CYCLE directories and extract the CYCLE time
CYCLES=$(ls -d $CYCLPATH/* | xargs -n 1 basename)

# # CYCLE=20170101T0000Z
# for CYCLE in $CYCLES; do
#     echo $CYCLE um2nc

#     # get list of um output directories in the cycle path
#     UMDIRS=$(ls -d $CYCLPATH/$CYCLE/*/*/*/um)

#     # loop over directories
#     for DIR in $UMDIRS; do
#         # get list of files in the directory
#         FILES=$(ls $DIR/umnsaa_*)

#         # loop over all files
#         for FILE in $FILES; do
#             # skip if FILE has . in name (um outputs have no extension)
#             if [[ $FILE == *"."* ]]; then
#                 continue
#             # skip if FILE has _cb in name (boundary outputs)
#             elif [[ $FILE == *"_cb"* ]]; then
#                 continue
#             fi

#             # check if file has already been processed
#             if [ -f ${FILE}.nc ]; then
#                 echo ${FILE}.nc already exists
#             else
#                 # convert to netcdf using um2nc
#                 # https://github.com/ACCESS-NRI/um2nc-standalone
#                 echo processing $FILE
#                 um2nc $FILE ${FILE}.nc

#             fi
#         done
#     done
# done

module purge
module load nco

# now concatenate nc files into one file per cycle
for CYCLE in $CYCLES; do
    echo $CYCLE ncrcat

    # get list of um output directories in the cycle path
    UMDIRS=$(ls -d $CYCLPATH/$CYCLE/*/*/*/um)

    # loop over directories
    for DIR in $UMDIRS; do
        # get list of files ending in three digits
        FILES=$(ls $DIR/umnsaa_*[0-9][0-9][0-9].nc)

        # get unique list of files, ignoring the last three digits .nc
        UNIQUE_FILES=$(echo $FILES | tr ' ' '\n' | sed 's/[0-9][0-9][0-9].nc//g' | sort | uniq)

        # concatenate FILES.nc
        for FILE in $UNIQUE_FILES; do
            # make nc dir if it doesn't exist
            mkdir -p $DIR/nc

            FNAME=$(basename $FILE)

            # check if file has already been processed
            if [ -f $DIR/nc/${CYCLE}_${FNAME}.nc ]; then
                echo $DIR/nc/${CYCLE}_${FNAME}.nc already exists
            else
                # concatenate files using ncrcat from nco
                echo processing ${FILE}* into ./nc/${CYCLE}_${FNAME}.nc
                ncrcat ${FILE}[0-9][0-9][0-9].nc $DIR/nc/${CYCLE}_${FNAME}.nc
            fi

        done
    done
done

echo done!
