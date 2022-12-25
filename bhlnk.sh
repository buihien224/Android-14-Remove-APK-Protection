#!/bin/bash
dir=$(pwd)
repS="python3 $dir/bin/strRep.py"

jar_util() 
{
	cd $dir
	#binary
	if [[ $3 == "fw" ]]; then 
		bak="java -jar $dir/bin/baksmali.jar d"
		sma="java -jar $dir/bin/smali.jar a"
	else
		bak="java -jar $dir/bin/baksmali-2.5.2.jar d"
		sma="java -jar $dir/bin/smali-2.5.2.jar a"
	fi

	if [[ $1 == "d" ]]; then
		echo -ne "====> Patching $2 : "
		if [[ -f $dir/services.jar ]]; then
			sudo cp $dir/services.jar $dir/jar_temp
			sudo chown $(whoami) $dir/jar_temp/$2
			unzip $dir/jar_temp/$2 -d $dir/jar_temp/$2.out  >/dev/null 2>&1
			if [[ -d $dir/jar_temp/"$2.out" ]]; then
				rm -rf $dir/jar_temp/$2
				for dex in $(find $dir/jar_temp/"$2.out" -maxdepth 1 -name "*dex" ); do
						if [[ $4 ]]; then
							if [[ ! "$dex" == *"$4"* ]]; then
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
				for fld in $(find -maxdepth 1 -name "*.out" ); do
					if [[ $4 ]]; then
						if [[ ! "$fld" == *"$4"* ]]; then
							$sma $fld -o $(echo ${fld//.out})
							[[ -f $(echo ${fld//.out}) ]] && rm -rf $fld
						fi
					else 
						$sma $fld -o $(echo ${fld//.out})
						[[ -f $(echo ${fld//.out}) ]] && rm -rf $fld	
					fi
				done
				7za a -tzip -mx=0 $dir/jar_temp/$2_notal $dir/jar_temp/$2.out/. >/dev/null 2>&1
				#zip -r -j -0 $dir/jar_temp/$2_notal $dir/jar_temp/$2.out/.
				zipalign 4 $dir/jar_temp/$2_notal $dir/jar_temp/$2
				if [[ -f $dir/jar_temp/$2 ]]; then
					sudo cp -rf $dir/jar_temp/$2 $dir/module/system/framework
					final_dir="$dir/module/*"
					#7za a -tzip "$dir/services_patched_$(date "+%d%m%y").zip" $final_dir
					echo "Success"
					rm -rf $dir/jar_temp/$2.out $dir/jar_temp/$2_notal 
				else
					echo "Fail"
				fi
			fi
		fi
	fi
}


services() {

	lang_dir="$dir/module/lang"

	jar_util d "services.jar" fw

	#patch signature

	s0=$(find -name "PermissionManagerServiceImpl.smali")
	[[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/updatePermissionFlags.config.ini $s0
	[[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/shouldGrantPermissionBySignature.config.ini $s0
	[[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/revokeRuntimePermissionNotKill.config.ini $s0
	[[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/revokeRuntimePermission.config.ini $s0
	[[ -f $s0 ]] && $repS $dir/signature/PermissionManagerServiceImpl/grantRuntimePermission.config.ini $s0

	s1=$(find -name "PermissionManagerServiceStub.smali")
	[[ -f $s1 ]] && echo $(cat $dir/signature/PermissionManagerServiceStub/onAppPermFlagsModified.config.ini) >> $s1
	
	s2=$(find -name "ParsingPackageUtils.smali")
	[[ -f $s2 ]] && $repS $dir/signature/ParsingPackageUtils/getSigningDetails.config.ini $s2

	s3=$(find -name 'PackageManagerService$PackageManagerInternalImpl.smali' )
	[[ -f $s3 ]] && $repS $dir/signature/'PackageManagerService$PackageManagerInternalImpl'/isPlatformSigned.config.ini $s3

	s4=$(find -name "PackageManagerServiceUtils.smali")
	[[ -f $s4 ]] && $repS $dir/signature/PackageManagerServiceUtils/verifySignatures.config.ini $s4

	s5=$(find -name "ReconcilePackageUtils.smali")
	[[ -f $s5 ]] && $repS $dir/signature/ReconcilePackageUtils/reconcilePackages.config.ini $s5

	s6=$(find -name "ScanPackageUtils.smali")
	[[ -f $s6 ]] && $repS $dir/signature/ScanPackageUtils/assertMinSignatureSchemeIsValid.config.ini $s6
	#[[ -f $s6 ]] && $repS $dir/signature/ScanPackageUtils/applyPolicy.configs.ini $s6
	
	jar_util a "services.jar" fw
}

if [[ ! -d $dir/jar_temp ]]; then

	mkdir $dir/jar_temp
	
fi

services

