export DEBEMAIL="seb.james@sheffield.ac.uk"
export DEBFULLNAME="Sebastian Scott James"
PACKAGE_MAINTAINER_GPG_IDENTITY="$DEBFULLNAME <$DEBEMAIL>"
PACKAGE_MAINTAINER_GPG_KEYID="E9C8DA2C"
CURRENT_YEAR=`date +%Y`

# I didn't end up using this information.
PROCESSORS=`grep "^physical id" /proc/cpuinfo | sort -u | wc -l`
CORES_PER_PROC=`grep "^core id" /proc/cpuinfo | sort -u | wc -l`
CORES=$((PROCESSORS * CORES_PER_PROC))
