#!/bin/bash

IDS=("ivxhi4tzhiytanrzg44dkmzz" "ivxhi4tzhiytcmjsgq2denzs" "ivxhi4tzhiytanzugmydonrt" "ivxhi4tzhiytanzxgyzdmnrv" "ivxhi4tzhiytaojsgm3tamjz" "ivxhi4tzhiytcmzsgazdmnrv" "ivxhi4tzhiytcmjvgm3dqnrq" "ivxhi4tzhiytcmjqheztaojz" "ivxhi4tzhi4tembzgqytmoa=" "ivxhi4tzhi4tembzgq4dgoa=" "ivxhi4tzhi4tembzgq3tsoa=" "ivxhi4tzhiytanzwg4zdonbr" "ivxhi4tzhi4tembzgq2tomy=" "ivxhi4tzhi4tembzgq2tioi=" "ivxhi4tzhi4tembzgqzdima=" "ivxhi4tzhi4tembzgqydkoi=" "ivxhi4tzhi4tembzgqztmoi=" "ivxhi4tzhiytaobwgq3tomrx" "ivxhi4tzhi4tembzgqytaoa=" "ivxhi4tzhi4tembzgq3deoi=" "ivxhi4tzhi4tembzgq2dgnq=" "ivxhi4tzhi4tembzgqzdsny=" "ivxhi4tzhi4tembzgqydsmi=" "ivxhi4tzhiytcmjvgq4tcnru" "ivxhi4tzhi4tembzgq4doni=" "ivxhi4tzhi4tembzgq3tmmi=" "ivxhi4tzhiytcmzrha2tqnrs" "ivxhi4tzhiytanzrg44tomzv" "ivxhi4tzhiytaobyguytcobq" "ivxhi4tzhi4tembzgqzdkna=" "ivxhi4tzhiytcmjqge3tcnzv" "ivxhi4tzhi4tembzgqydimq=" "ivxhi4tzhi4tembzgq2tgnq=" "ivxhi4tzhi4tembzgq4dmoa=" "ivxhi4tzhi4tembzgq2dmoi=" "ivxhi4tzhiytanzrgu2dcmrs" "ivxhi4tzhi4tembzgq4dany=" "ivxhi4tzhiytcmbzg42tqmbw" "ivxhi4tzhiytanzugq3dcnbq" "ivxhi4tzhi4tembzgq3dini=" "ivxhi4tzhiytcmjygeztsobx" "ivxhi4tzhiytcmbwge4tomrr" "ivxhi4tzhiytcmjxhaztiobt" "ivxhi4tzhiytanzxgizdmnjr")
REQUEST="https://picks.cbssports.com/graphql?operationName=EntryDetailsQuery&variables=%7B%22periodId%22:%22current%22,%22entryId%22:%22__ENTRY_ID__%22%7D&extensions=%7B%22persistedQuery%22:%7B%22version%22:1,%22sha256Hash%22:%222d184572d3a2a483120c56a982f128c021e96b08e96eff044b3a112a41947cbf%22%7D%7D"

for i in "${IDS[@]}"
do
    echo "$i"
    req="${REQUEST/__ENTRY_ID__/${i}}"
    echo "$req"
    curl "${req}" -o "$i.json"
    sleep 2
done