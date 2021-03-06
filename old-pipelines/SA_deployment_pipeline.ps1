# step 1: update flow properties
$source_file_name = "SA-plh-international-flavour"
$input_path_1 = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-international-repo\flows\" + $source_file_name + ".json"
$source_file_name = $source_file_name + "_expire"
$output_path_1 = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-international-repo\temp\" + $source_file_name + ".json"
node .\idems-chatbot-repo\scripts\update_expiration_time.js $input_path_1 60 $output_path_1
Write-Output "updated expiration"

# step 2: flow edits & A/B testing
$deployment = "south-africa"
$SPREADSHEET_ID_ab = '1KPakZyyuyHoRO5GCdyde-vOvKq2155pTl-VZKKIKcXI'
$SPREADSHEET_ID_loc = '1BZ6zKNwglzz8e3qhx1YCOMYxiSSnbDvRb3YxF-vvf_4'
$JSON_FILENAME = $output_path_1
$source_file_name = $source_file_name + "_ABtesting"
$CONFIG_ab = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-" + $deployment + "-repo\edits\ab_config_demo.json"
$output_path_2 = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-" + $deployment + "-repo\temp\" + $source_file_name + ".json"
Set-Location "C:\Users\fagio\Documents\rapidpro_abtesting"
python .\main.py $JSON_FILENAME $output_path_2 $SPREADSHEET_ID_ab $SPREADSHEET_ID_loc --format google_sheets --logfile main_AB.log --config=$CONFIG_ab
Write-Output "added A/B tests and localisation"
$output_path_3 = $output_path_2
<#
## step 3: localisation
$SPREADSHEET_ID = '1BZ6zKNwglzz8e3qhx1YCOMYxiSSnbDvRb3YxF-vvf_4'
$JSON_FILENAME = $output_path_2
$source_file_name = $source_file_name + "_localised"
$output_path_3 = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-" + $deployment + "-repo\temp\" + $source_file_name + ".json"
python main.py $JSON_FILENAME $output_path_3 $SPREADSHEET_ID --format google_sheets --logfile main_loc.log
Write-Output "localised flows"
#>

Set-Location "C:\Users\fagio\Documents\parenttext-deployment"


#step 4T: add translation and add quick replies to message text

$languages =  @("afr","sot","tsn","xho","zul")
$2languages = @("af","st","tn","xh","zu")
$deployment_ = "south_africa"

$input_path_T = $output_path_3
for ($i=0; $i -lt $languages.length; $i++) {
	$lang = $languages[$i]
    $2lang = $2languages[$i]

    #step T: get PO files from translation repo and merge them into a single json
    $transl_repo = "C:\Users\fagio\Documents\GitHub\PLH-Digital-Content\translations\parent_text\" + $2lang+ "\"
    $intern_transl = $transl_repo +  $2lang + "_messages.po"
    $local_transl = $transl_repo +  $2lang+ "_" + $deployment_ + "_additional_messages.po"

    $json_intern_transl = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-"+ $deployment +"-repo\temp\temp_transl\"+ $lang+ "\"  +$2lang + "_messages.json"
    node C:\Users\fagio\Documents\idems_translation\common_tools\index.js convert $intern_transl $json_intern_transl

    $json_local_transl = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-"+ $deployment +"-repo\temp\temp_transl\"+ $lang+ "\" +$2lang+ "_" + $deployment +"_additional_messages.json"
    node C:\Users\fagio\Documents\idems_translation\common_tools\index.js convert $local_transl $json_local_transl

    $json_translation_file_path = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-"+ $deployment +"-repo\temp\temp_transl\"+ $lang+ "\" + $2lang+ "_all_messages.json"
    node C:\Users\fagio\Documents\idems_translation\common_tools\concatenate_json_files.js $json_local_transl $json_intern_transl $json_translation_file_path 


    $source_file_name = $source_file_name + "_" + $lang
    $output_name_T = $source_file_name
    $transl_output_folder = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-" + $deployment + "-repo\temp"
    node C:\Users\fagio\Documents\idems_translation\chatbot\index.js localize $input_path_T $json_translation_file_path $lang $output_name_T $transl_output_folder
   

    $input_path_T = $transl_output_folder + "\" + $output_name_T +".json"
    Write-Output ("created localization for " + $lang)
}

# step 4QA: integrity check

$InputFile = $transl_output_folder + "\" + $output_name_T +".json"
$OutputDir = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-"+ $deployment +"-repo\temp\temp_transl"
$JSON9 = "9_has_any_words_check"
$JSON9Path = $OutputDir + '\' + $JSON9 + '.json'
$LOG10 = "10 - Log of changes after has_any_words_check"
$JSON11 = "11_fix_arg_qr_translation"
$JSON11Path = $OutputDir + '\' + $JSON11 + '.json'
$LOG12 = "12 - Log of changes after fix_arg_qr_translation"
$LOG13 = "13 - Log of erros in file found using overall_integrity_check"
$LOG14 = $OutputDir + "\Excel Acceptance Log.xlsx"
    
Node C:\Users\fagio\Documents\GitHub\idems_translation\chatbot\index.js has_any_words_check $InputFile $OutputDir $JSON9 $LOG10
Node C:\Users\fagio\Documents\GitHub\idems_translation\chatbot\index.js fix_arg_qr_translation $JSON9Path $OutputDir $JSON11 $LOG12
Node C:\Users\fagio\Documents\GitHub\idems_translation\chatbot\index.js overall_integrity_check $JSON11Path $OutputDir $LOG13 $LOG14

Write-Output "Completed integrity check"



# step 4: add quick replies to message text and translation
$input_path_4 = $JSON11Path 
#$input_path_4 = $transl_output_folder + "\" + $output_name_T +".json"
$source_file_name = $source_file_name + "_no_QR"
$select_phrases_file = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-" + $deployment + "-repo\edits\select_phrases.json"
$output_path_4 = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-" + $deployment + "-repo\temp\"
$output_name_4 = $source_file_name 
node C:\Users\fagio\Documents\idems_translation\chatbot\index.js move_quick_replies $input_path_4 $select_phrases_file $output_name_4 $output_path_4
Write-Output "removed quick replies"


$input_path_5 = $output_path_4 + $output_name_4 +".json"
$source_file_name = $source_file_name + "_safeguarding"
$output_path_5 = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-" + $deployment + "-repo\temp\"+ $source_file_name +".json"
$safeguarding_path = "C:\Users\fagio\Documents\parenttext-deployment\parenttext-" + $deployment + "-repo\edits\" + $deployment_ + "_safeguarding.json"
node ..\Github\safeguarding-rapidpro\add_safeguarding_to_flows_mult_lang.js $input_path_5 $safeguarding_path $output_path_5
Write-Output "added safeguarding"

# step final: split in 2 json files because it's too heavy to load (need to replace wrong flow names)
$input_path_6 = $output_path_5
node .\idems-chatbot-repo\scripts\split_in_multiple_json_files.js $input_path_6 2

