#!/bin/bash
dir=$(pwd)
repM="python3 $dir/bin/strRep.py"

get_file_dir() {
	if [[ $1 ]]; then
		test=$(sudo find "$dir/img_temp/" -type f -name "$1")
		for i in $test; do
			echo $i
		done
	else 
		return 0
	fi

}


mvst() {
	scr_folder=$(dirname $(sudo find -name $1 | sed -e 's,^\./,,' ))
	if [[ $3 ]]; then
		scr_folder=$(echo $scr_folder | cut -d'/' -f2-)
	fi
	des_folder=$(sudo find -name $2 | sed -e 's,^\./,,')
	mkdir -p $des_folder/$scr_folder
	mv $(sudo find -type f -name $1 | sed -e 's,^\./,,' ) $des_folder/$scr_folder

}

jar_util() 
{
	cd $dir

	if [[ ! -d $dir/jar_temp ]]; then
		mkdir $dir/jar_temp
	fi

	bak="java -jar $dir/bin/baksmali.jar d"
	sma="java -jar $dir/bin/smali-2.5.2.jar a"


	if [[ $1 == "d" ]]; then
		echo -ne "====> Patching $2 : "
		if [[ $(get_file_dir $2 ) ]]; then
			sudo cp $(get_file_dir $2 ) $dir/jar_temp
			sudo chown $(whoami) $dir/jar_temp/$2
			unzip $dir/jar_temp/$2 -d $dir/jar_temp/$2.out  >/dev/null 2>&1
			if [[ -d $dir/jar_temp/"$2.out" ]]; then
				rm -rf $dir/jar_temp/$2
				for dex in $(sudo find $dir/jar_temp/"$2.out" -maxdepth 1 -name "*dex" ); do
						if [[ $4 ]]; then
							if [[ "$dex" != *"$4"* && "$dex" != *"$5"* ]]; then
								$bak $dex -o "$dex.out"
								[[ -d "$dex.out" ]] && rm -rf $dex
							fi
						else
							$bak $dex -o "$dex.out"
							[[ -d "$dex.out" ]] && rm -rf $dex		
						fi

				done
			fi
		fi
	else 
		if [[ $1 == "a" ]]; then 
			if [[ -d $dir/jar_temp/$2.out ]]; then
				cd $dir/jar_temp/$2.out
				for fld in $(sudo find -maxdepth 1 -name "*.out" ); do
					if [[ $4 ]]; then
						if [[ "$fld" != *"$4"* && "$fld" != *"$5"* ]]; then
							$sma $fld -o $(echo ${fld//.out}) --api 34
							[[ -f $(echo ${fld//.out}) ]] && rm -rf $fld
						fi
					else 
						$sma $fld -o $(echo ${fld//.out}) --api 34
						[[ -f $(echo ${fld//.out}) ]] && rm -rf $fld	
					fi
				done
				7za a -tzip -mx=0 $dir/jar_temp/$2_notal $dir/jar_temp/$2.out/. >/dev/null 2>&1
				#zip -r -j -0 $dir/jar_temp/$2_notal $dir/jar_temp/$2.out/.
				$zipalign_sa -p -v 4 $dir/jar_temp/$2_notal $dir/jar_temp/$2  >/dev/null 2>&1
				if [[ -f $dir/jar_temp/$2 ]]; then
					rm -rf $dir/jar_temp/$2.out $dir/jar_temp/$2_notal 
					sudo cp -rf $dir/jar_temp/$2 $(get_file_dir $2) 
					echo "Succes"
				else
					echo "Fail"
				fi
			fi
		fi
	fi
}


repM () {
	if [[ $4 == "r" ]]; then
		if [[ -f $3 ]]; then
			$repM $1 $2 $3
		fi
	elif [[ $4 == "f" ]]; then
		for i in $3; do
			$repM $1 $2 $i
		done
	else
		file=$(sudo find -name $3)
		if [[ $file ]]; then
			$repM $1 $2 $file
		fi
	fi
}

framework() {

	jar_util d 'framework.jar' fw 5 5

	count=$(ls -dq classes* | wc -l)
	mkdir "classes$count.dex.out"

	repM 'getMinimumSignatureSchemeVersionForTargetSdk' true ApkSignatureVerifier.smali
 
	mvst 'ApkSignatureVerifier.smali' "classes$count.dex.out" 
	
	jar_util a 'framework.jar' fw 5 5
}

services() {
	
	jar_util d "services.jar" fw

	count=$(ls -dq classes* | wc -l)
	mkdir "classes$count.dex.out" 

	repM 'isPlatformSigned' true 'PackageManagerService$PackageManagerInternalImpl.smali'
	repM 'isSignedWithPlatformKey' true 'PackageImpl.smali'

	mvst 'PackageManagerService$PackageManagerInternalImpl.smali' "classes$count.dex.out" 
	mvst 'PackageImpl.smali' "classes$count.dex.out" 
		
	jar_util a "services.jar" fw
}


if [[ ! -d $dir/jar_temp ]]; then

	mkdir $dir/jar_temp
	
fi

framework
services

if  [ -f $dir/jar_temp/framework.jar ]; then
		sudo cp -rf $dir/jar_temp/*.jar $dir/module/system/framework
	else
		echo "Fail to copy framework"
fi

