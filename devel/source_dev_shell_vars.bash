# ------------------------------------------------------------------
# 'source' this script to update ENV vars to make the Rapi::Blog repo
# this file is contained in active for your shell for development.
#
# This will update the following environment variables, preserving
# existing values (i.e. appending vs replacing) appropriately
#
#  * PERLLIB
#  * PATH
#  * RAPI_BLOG_SHARE_DIR
#
# ------------------------------------------------------------------

if [ $0 == ${BASH_SOURCE[0]} ]; then
  echo "Oops! This script needs to be 'sourced' to work -- like this:";
  echo -e "\n  source $0\n";
  exit 1;
fi;

do_source_vars() {
  local dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
  local prl="print_dev_exports.pl"
  
  if [ -e "$dir/$prl" ]; then
    local export_cmds;
    export_cmds=`perl $dir/$prl`;
    local exit=$?;
    if [ $exit -ne 0 ]; then
      echo "An error occured calling $dir/$prl (exit: $exit)";
    else
      eval $export_cmds;
      exit=$?;
      if [ $exit -ne 0 ]; then
        echo "An unknown error occured attempting to export shell variables";
      else
        echo " -- Exported Rapi::Blog env variables to your shell: --";
        echo -e "\n$export_cmds\n";
      fi;
    fi;
  else
    echo "Error! $prl script not found! Did you move this script?";
    # note: we're not calling exit here because we've been sourced 
    # and this would cause the parent shell to exit
  fi;
}

do_source_vars;
