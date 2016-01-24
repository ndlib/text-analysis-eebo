#!/bin/bash

# make-everything.sh - one script to rule them all

# Eric Lease Morgan <emorgan@nd.edu>
# June 13, 2015     - first cut; siphoned off build-corpus to another file
# June 15, 2015     - saved transform to a separate process
# December 31, 2015 - added call to update-db.sh
# January 18, 2016  - started adding creation of POS files


# configure
ROOT=/var/www/html/eebo

# get input
NAME=$1
IDENTIFIERS=$2

# sanity check; needs additional error checking
if [ -z $NAME -a -z $IDENTIFIERS ]; then

    echo "Usage: $0 <name> <identifiers>"
    exit 1
    
fi

# initialize
cd $ROOT

# state #1 - build corpus
echo "building corpus"
cat $IDENTIFIERS | ./bin/make-corpus.sh $NAME

# transform TEI to HTML; commented out because it takes a long time and requires java
echo "transforming TEI to HTML"
./bin/transform-xml2html.sh $NAME 

# stage #2 - create the index
echo "making index"
./bin/make-index.sh $NAME

# create POS files; commented out because it takes a long time
echo "making POS files"
./bin/transform-xml2pos.sh $NAME

# make dictionary
echo "making dictionary"
./bin/make-dictionary.py $NAME/index/ > $NAME/dictionary.db

# extract unique words
echo "extracting unique words"
cat $NAME/dictionary.db | ./bin/make-unique.py  > $NAME/unique.db

# stage #3 - create the catalog
echo "building catalog"
./bin/make-catalog.sh $NAME

# stage #4 - create sorted numeric reports
echo "creating numeric reports"
./bin/calculate-size.sh   $NAME                      | sort -k2 -n -r > $NAME/sizes.db
./bin/calculate-themes.sh $NAME etc/theme-colors.txt | sort -k2 -g -r > $NAME/calculated-colors.db
./bin/calculate-themes.sh $NAME etc/theme-names.txt  | sort -k2 -g -r > $NAME/calculated-names.db
./bin/calculate-themes.sh $NAME etc/theme-ideas.txt  | sort -k2 -g -r > $NAME/calculated-ideas.db

# create reports, sorted by coefficient: colors, names, ideas
echo "calculating themes"
./bin/calculate-themes.py -v $NAME/dictionary.db etc/theme-colors.txt > $NAME/dictionary-colors.db
./bin/calculate-themes.py -v $NAME/dictionary.db etc/theme-names.txt  > $NAME/dictionary-names.db
./bin/calculate-themes.py -v $NAME/dictionary.db etc/theme-ideas.txt  > $NAME/dictionary-ideas.db

# create charts; R needs to be installed (oops!); commented out so people don't need R, yet
echo "making graphs"
./bin/make-graphs.sh $NAME

# state 5 - analyze corpus and create pretty about page
echo "making about page"
./bin/make-about.sh $NAME > $NAME/about.db
./bin/transform-about2html.py $NAME > $NAME/about.html

# stage 6 - update list (database) of collections
echo "updating database"
./bin/update-db.sh $NAME

# stage 7 - done
echo "done"
exit 0




