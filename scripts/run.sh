#!/bin/bash
set -x
yum install jq -y
echo "++++++++++++++++++++++++++++++++++++++++++++ 初始化整个集成测试环境 ++++++++++++++++++++++++++++++++++++++++++++"

if [[ $JOB_NAME =~ "arch-jssdk" ]]
then
  echo "提示： jssdk的MR合入单测"
  rm -f generate_test_package.sh
  curl -O http://nexus.hyperchain.cn/repository/hyper-test/sdk/prepare_files/generate_test_package.sh
  source ./generate_test_package.sh
else
  echo "未知的job，请检查"
  exit 1
fi

# 启动ssh服务
ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
nohup /usr/sbin/sshd -D &
echo root:hyperchain | chpasswd

echo "+++++++++++++++++++ 更新节点启动配置文件 +++++++++++++++++++"
#修改Chain.toml的内容
sed -i "/^node_url/c node_url=\"${PKG_URL}\"" ./scripts/Chain.toml
sed -i "/^chain_type/c chain_type=\"${BIN}\"" ./scripts/Chain.toml
sed -i "/^chain_version/c chain_version=\"${VER}\"" ./scripts/Chain.toml
cp ./scripts/Chain.toml ./scripts/defaultChain.toml #复制一份作为默认Chain.toml

# 修改hpc中的二进制版本，用于节点启动状态验证
sed -i "/^FlatoVersion/c FlatoVersion=${VER}" ./scripts/hpc.properties

echo "++++++++++++++++++++++++++++++++++++++++++++ 启动节点 ++++++++++++++++++++++++++++++++++++++++++++"
#启动节点
cd ./scripts
curl -O http://nexus.hyperchain.cn/repository/hyper-test/scripts/nodeStart.jar
java -jar nodeStart.jar
cd ../
echo "++++++++++++++++++++++++++++++++++++++++++++ 启动节点完成 ++++++++++++++++++++++++++++++++++++++++++++"

echo "++++++++++++++++++++++++++++++++++++++++++++ 当前版本信息为 ++++++++++++++++++++++++++++++++++++++++++++"
export TAG=$TAG #版本的tag，v0.0.5-1; vExtraID1.0.11-1;
echo "TAG=$TAG"
export VER=$VER #版本信息，1.5.0; latest;
echo "VER=$VER"
export PKG=$PKG #测试包名
echo "PKG=$PKG"
export PKG_URL=$PKG_URL #测试包的拉取url
echo "PKG_URL=$PKG_URL"
export BRANCH=$BRANCH #tag、smoke、coverage
echo "BRANCH=$BRANCH"
export BIN=$BIN #flato or hyperchain
echo "BIN=$BIN"

echo "++++++++++++++++++++++++++++++++++++++++++++ 开始执行用例 ++++++++++++++++++++++++++++++++++++++++++++"
echo "---------- 根据分支选择执行的用例 ----------"
runCaseCmd="npm run test"
echo "---------- 执行用例 ----------"
eval $runCaseCmd 2>&1 | tee runCase.log

echo "---------- 检查结果 ----------"
grep -iE "sh: jest: command not found" runCase.log
if [ $? -eq 0 ]; then
  echo "testcase的路径填写有误，请检查！！！"
  exit 1
fi

grep "Test Suites.*passed" runCase.log
if [ $? -eq 1 ]; then
  echo "没有执行通过的用例，请检查！！！"
  exit 1
fi

grep "Test Suites.*failed" runCase.log
if [ $? -eq 0 ]; then
  echo "任务运行失败，请检查！！！"
  exit 0  # 等待单测脚本全部没问题后需改成1
else
  echo "Cases passed！！！"
fi
set +x
