
if([[ -z "$1" ]]); then
echo "需要指定当前部署的版本，用法$0 <tag名称> [tag匹配模式] [commit查找目录]"
echo "   如：$0 v237 v* src"
exit 1
fi
# 当前部署版本tag
currentTag=$1
# 查找tag模式，默认为"v*"
pattern=${2:-'v*'}
# 查找commit目录，默认为当前目录"."
directory=${3:-'.'}

gitUrl=`echo ${GIT_URL} | sed -e 's/\:\/\/.*@/\:\/\//'`
# 检测Tag是否存在
tagExistCmd="git tag --list --sort=\"-v:refname\" | awk '{if(\$0 == \"${1}\"){print}}'"
# echo $tagExistCmd
tagExists="`eval $tagExistCmd`"
if [[ -z "$tagExists" ]]; then
    echo "Git Repo $gitUrl 中未发现 tag [$1]"
    exit 1;
fi

# 获取最新Tag
latestTag=`git tag --list ${pattern} --sort="-v:refname" | head -n 1`
# 查询上一个最近部署版本Tag
# git tag --list v* --sort="-v:refname" | awk '{array[NR]=$0;find=0;} END { for(i=NR;i>0;i--){if(array[i]=="v247"){find=1;}{if(!find){print array[i];}}}};' | tail -n 1
previousCmd="git tag --list ${pattern} --sort=\"-v:refname\" | awk '{array[NR]=\$0;find=0;} END { for(i=NR;i>0;i--){if(array[i]==\"${currentTag}\"){find=1;}{if(!find){print array[i];}}}};' | tail -n 1"

# echo 当前版本Tag：$1
# echo 查询上一个最近部署版本Tag...
# echo $previousCmd
previousTag="`eval $previousCmd`"
# echo 查询结果：$previousTag

[[ -n $previousTag ]] && previousTag="^"$previousTag
# 获取2个Tag间的所有commit
commitsCmd="git log --no-merges --pretty=\"%s\" ${previousTag} ${currentTag} -- ${directory} | sort -n | awk '{if(!a[\$1]++){if(\$2 && \$1 ~ /[0-9]+[,:]?$/){sub(/[,:]/,\"\",\$1);printf(\"<li><a href=\\\"https://issue.hubenlv.com/browse/%s\\\">%s</a></li>\n\",\$1, \$0)}else{printf(\"<li>%s</li>\n\", \$0)}}}'"
# echo 获取版本【$1】与【$previousTag】间的改动...
# echo $commitsCmd
# echo 版本间改动如下：
previousTag="`eval $commitsCmd`"

if([ $latestTag != $currentTag ]) then
echo "<p style='color: red'><b>Warning: 当前部署版本${currentTag}，非最新版本${latestTag}！</b><p>"
fi

echo "<p>代码仓库：<a href='${gitUrl}'>${gitUrl}</a></p>"
echo
echo "<p><b>Relase Notes:</b> </p>"
if([[ -n $previousTag ]]) then
echo "<ol>"
echo $previousTag
echo "</ol>"
fi

echo "Check console output at <a href='${BUILD_URL}'>${BUILD_URL}</a> to view the results."
