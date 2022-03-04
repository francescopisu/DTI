set -e

# add folder to matlab search path
#matlab -nodisplay -r "addpath('.');exit"

project=6145e13e7a38b058dca18853

# download tractogram and wmc classification from tractseg
datatype_tract="neuro/track/tck"
datatype_wmc="neuro/wmc"

#only need to run this once
bl data query --limit 10000 --project $project --datatype $datatype_tract --json | jq . > meta_tract.json
bl data query --limit 10000 --project $project --datatype $datatype_wmc --json | jq . > meta_wmc.json

# old: jq -r '.[].meta.subject' all.json | sort -u
#for subject in $(jq -r '.[].subject' subjects.json)

#outdir="../input/"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )";
PARENT_DIRECTORY="${DIR%/*}"
outdir="${PARENT_DIRECTORY}/output/statistics"
indir="${PARENT_DIRECTORY}/input"
config_path="config.json"

for subject in $(jq -r '.[].meta.subject' meta_wmc.json)
do
    echo "Subject no. $subject.."
    tract_ids=$(jq -r '.[] | select(.meta.subject == '\"$subject\"') | ._id' meta_tract.json)
    wmc_ids=$(jq -r '.[] | select(.meta.subject == '\"$subject\"') | ._id' meta_wmc.json)

    # first: tractogram. 
    # Look for `TRACT FROM MRTRIX3`
    for id in $tract_ids
    do
        tags=$(jq -r '.[] | select(._id=='\"$id\"') | .tags | join(".")' meta_tract.json)
        if [ "$tags" == "TRACT from MRTRIX3" ]; then
            bl data download $id --directory $outdir
        fi
    done

    # second: wmc classification w/ tracts and surfaces
    # Look for `WMC from MRTRIX3`
    for id in $wmc_ids
    do
        tags=$(jq -r '.[] | select(._id=='\"$id\"') | .tags | join(".")' meta_wmc.json)
        if [ "$tags" == "WMC from MRTRIX3" ]; then
            bl data download $id --directory $outdir
        fi 
    done

    # extract tracts' statistics
    echo "Extracting tracts' statistics.."
    matlab -nodisplay -r "computeTractsStatistics('$subject', '$config_path');exit"

    # delete files and proceed to the next subject
    rm -rf $indir/classification.mat $indir/track.tck $indir/surfaces $indir/tracts
done