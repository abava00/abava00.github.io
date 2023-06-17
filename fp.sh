# fix punctuation

# replace  ． -> ．
rg -l ． | xargs sed -i "s/．/．/g"
# replace  ， -> ，
rg -l ， | xargs sed -i "s/，/，/g"
