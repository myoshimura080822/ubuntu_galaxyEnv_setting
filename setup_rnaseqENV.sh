#!/bin/bash

echo "################################################"
echo " setup_rnaseqENV started ..."
echo "################################################"
echo " "

galaxy_setting=1

if [ $# -ne 1 ]; then
    echo "Starting without galaxy-setting mode..." 1>&2
    echo
    galaxy_setting=0
fi

UID=`id | sed 's/uid=\([0-9]*\)(.*/\1/'`
if [ $UID -ne 0 ]; then
    echo "Current user is Not root."
    exit 1
fi

script_dir="$(pwd)"

# output logDir
DATE=`date '+%F_%R'`
LOGDIR=./log/rnaseqENV
LOGFILE=$LOGDIR/$DATE.log

source_dir='/usr/local/src'

lib_dir='/usr/local/lib'
bam_dir='/usr/local/include/bam'

samtools_name='samtools-0.1.19'
samtools_file='samtools-0.1.19.tar.bz2'
samtools_source='http://sourceforge.net/projects/samtools/files/samtools/0.1.19/'$samtools_file
samtools_path=$source_dir'/'$samtools_name

sailfish_name='Sailfish-0.6.3-Linux_x86-64'
sailfish_file='Sailfish-0.6.3-Linux_x86-64.tar.gz'
sailfish_source='https://github.com/kingsfordgroup/sailfish/releases/download/v0.6.3/'$sailfish_file
sailfish_path=$source_dir'/'$sailfish_name

galaxy_user=$1
galaxy_path=/usr/local/$1/galaxy-dist
galaxy_ini='universe_wsgi.ini'
galaxy_dep_dir='dependency_dir'
GALAXY_MASTER_API_KEY=`date --rfc-3339=ns | md5sum | cut -f 1 -d ' '`

chk_samtools_path=`echo $PATH | grep $samtools_path`
chk_sailfish_path=`echo $PATH | grep -e $sailfish_path/bin`
chk_sailfish_lib=`echo $LD_LIBRARY_PATH | grep -e $sailfish_path/lib`

bashrc_path='/etc/bash.bashrc'
echo $bashrc_path
echo $chk_samtools_path
echo $chk_sailfish_path
echo $chk_sailfish_lib

# methods
create_dir()
{
    if [ ! -d $1 ]; then
        echo -e "Creatind direcorty..."
        mkdir -pv $1
    else
        echo -e "$1 already exist...continuing"
    fi
}

r_prep()
{
    echo -e ">>>>> start r_prep ..."
    echo " "
    R --vanilla < $script_dir/install_rnaseqENV.R
    echo " "
    echo -e ">>>>> end of r_prep ..."
}

python_prep()
{
    echo -e ">>>>> start python_prep ..."
    echo " "
    
    pip install python-dateutil
    pip install bioblend
    pip install pandas
    pip install grequests
    pip install GitPython

    pip install pip-tools
    pip-review

    echo " "
    echo -e ">>>>> end of python_prep ..."
}

samtools_prep()
{
    echo -e ">>>>> start samtools_prep ..."
    echo " " 
    cd $source_dir

    if [ -d $samtools_path ];then
        echo -e "samtools already downloaded."
    else
        echo -e "Download and Installing samtools..."
        wget $samtools_source
        tar jxvf $samtools_file
        cd $samtools_name
        make
        chown -R $galaxy_user $samtools_path
    fi

    if [ ! -f $lib_dir/libbam.a ];then
        cp libbam.a $lib_dir
    else
        echo -e "samtools libbam.a already copied."
    fi

    if [ ! -d $bam_dir ];then
        mkdir $bam_dir
        cp *.h $bam_dir
    else
        echo -e "samtools bam-dir already exists."
    fi

    if [ -z "$chk_samtools_path" ]; then
        echo -e "samtools PATH setting..."
        echo $PATH 
        echo PATH=\$PATH:$samtools_path >> $bashrc_path
        echo export PATH >> $bashrc_path
        export PATH=$PATH:/usr/local/src/samtools-0.1.19
    else
        echo -e "samtools PATH already setting."
    fi

    echo " "
    echo -e ">>>>> end of samtools_prep ..."
}

sailfish_prep()
{
    echo -e ">>>>> start sailfish_prep ..."
    echo " " 
    cd $source_dir

    if [ -d $sailfish_path ];then
        echo -e "sailfish already downloaded."
    else
        echo -e "Download and Installing sailfish..."
        wget $sailfish_source
        tar zxvf $sailfish_file
        chown -R $galaxy_user $sailfish_path
    fi

    if [ -z "$chk_sailfish_path" ]; then
        echo -e "sailfieh PATH setting..."
        echo $PATH 
        echo PATH=\$PATH:$sailfish_path/bin >> $bashrc_path
        echo export PATH >> $bashrc_path
        export PATH=$PATH:/usr/local/src/Sailfish-0.6.3-Linux_x86-64/bin
    else
        echo -e "sailfish PATH already setting."
    fi

    if [ -z "$chk_sailfish_lib" ] ; then
        echo -e "sailfish-lib PATH setting..."
        echo $LD_LIBRARY_PATH 
        echo LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:$sailfish_path/lib >> $bashrc_path
        echo export LD_LIBRARY_PATH >> $bashrc_path
        if [ -f $sailfish_path/lib/libz.so.1 ]; then
            mv $sailfish_path/lib/libz.so.1 $sailfish_path/lib/libz.so.1_bk
        fi
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/src/Sailfish-0.6.3-Linux_x86-64/lib
    else
        echo -e "sailfish-lib in LD_LIBRARY_PATH already setting."
    fi

    echo " "
    echo -e ">>>>> end of sailfish_prep ..."
}

setting_galaxy()
{

    echo -e ">>>>> start setting_galaxy ..."
    echo " "
    
    if [ -d $galaxy_path ]; then
        if [ ! -d $galaxy_path/$galaxy_dep_dir ]; then
            mkdir -m 755 $galaxy_path/$galaxy_dep_dir
            chown -R $galaxy_user $galaxy_path/$galaxy_dep_dir
        else
            echo -e "galaxy tool_dependency_dir is already exist."
        fi
        
        sed -i -e "s/#tool_dependency_dir/tool_dependency_dir/" $galaxy_path/$galaxy_ini
        sed -i -e "s/^tool_dependency_dir\(.*\)/tool_dependency_dir = $galaxy_dep_dir/" $galaxy_path/$galaxy_ini
        sed -i -e "s/#master_api_key/master_api_key/" $galaxy_path/$galaxy_ini
        sed -i -e "s/^master_api_key\(.*\)/master_api_key = $GALAXY_MASTER_API_KEY/" $galaxy_path/$galaxy_ini
    else
        echo "galaxy-dist Dir not found."
    fi

    echo " "
    echo -e ">>>>> end of setting_galaxy..."
}

main()
{
    r_prep
    echo
    python_prep
    echo
    samtools_prep
    echo
    sailfish_prep
    echo

    if [ $galaxy_setting -ne 0 ]; then
        setting_galaxy
        echo
        service galaxy restart
    fi
        
}

create_dir $LOGDIR
{
    main
} >> $LOGFILE 2>&1

echo " "
echo "################################################"
echo " setup_rnaseqENV all done." 
echo "################################################"
