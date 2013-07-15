#!/bin/bash
#
# This script just creates a project tree in target folder, 
# generates a SBT build script and setups my favourite plugins.
# This script is published under CC Attribution 3.0 Unported license.
#
# http://creativecommons.org/licenses/by/3.0/legalcode
# 
#
# Usage notes:
#
# ./init-scala.sh -t target_folder [-n project_name] [-v version] [-p] [-i] [-d]
# 
# Options list:
#   -t - Target folder for project. The whole folder will be used for the project if -p option is not passed.
#
#   -n - Project name. Will be used in SBT build file as project name. Also it will make new folder in the target folder if
#		 it is not the same.
#	  -v - Flag indicating a version of the project. By default it sets 0.0.1.0 version in SBT file.
#   -p -

function usage() 
{
cat << EOF
usage: $0 options

This script just creates a project tree in target folder, 
generates a SBT build script and set-ups my favourite plugins.

OPTIONS:
   -h      Show this message
   -t      Target folder for project
   -n      Project name      
   -p      Include plugins.sbt file into project flag.
   -i      Set up project as Intellij IDEA
   -d      Set up common dependencies flag. By default they are:
             scalaz
             scalatest
             scalalogging
   -v      Scala version
EOF
}

function extract_folder_name()
{
  echo `echo $1 | egrep -o '([^/]*)$'`
}

function initialize_folder_structure()
{
  mkdir -p ${TARGET_FOLDER}/{project,lib/provided}
  mkdir -p ${TARGET_FOLDER}/src/{main/{scala,java,resources},'test'/{scala,java,resources}}
}

function build_sbt() 
{
cat << EOF

import AssemblyKeys._

name := "${PROJECT_NAME}"

version := "0.0.1"

organization := "org.example"

scalaVersion := "${SCALA_VERSION}"

net.virtualvoid.sbt.graph.Plugin.graphSettings



resolvers ++= Seq("Typesafe repository" at "http://repo.typesafe.com/typesafe/releases/",
                  "Sonatype snapshots"  at "http://oss.sonatype.org/content/repositories/snapshots/",
                  "Sonatype releases"  at "http://oss.sonatype.org/content/repositories/releases",
                  "Central Maven Repository" at "http://repo1.maven.org/maven2/releases")

unmanagedJars in Provided <<= baseDirectory map { base => (base / "lib" / "provided" ** "*.jar").classpath }

unmanagedJars in Compile  <++= baseDirectory map { base =>
 val compile = base / "lib" / "compile"
 val provided = base / "lib" / "provided"
 ((compile ** "*.jar") +++ (provided ** "*.jar")).classpath
}

libraryDependencies ++= Seq(
 "com.typesafe" %% "scalalogging-slf4j" % "1.0.1",
 "org.specs2" %% "specs2" % "1.14" % "test",
 "commons-collections" % "commons-collections" % "3.0",
 "commons-logging" % "commons-logging" % "1.1.3",
 "commons-configuration" % "commons-configuration" % "1.8"
)

unmanagedJars in Test <++= baseDirectory map { base => (base / "lib" / "test" ** "*.jar").classpath }

assemblySettings

assembleArtifact in packageScala := false

EOF
}

function plugins_sbt()
{
  cat << EOF
addSbtPlugin("com.eed3si9n" % "sbt-assembly" % "0.8.8")

addSbtPlugin("com.github.mpeltonen" % "sbt-idea" % "1.4.0")

addSbtPlugin("net.virtual-void" % "sbt-dependency-graph" % "0.7.4")
EOF
}

while getopts "t:p:v:iph" opt; do
  case $opt in
    t)
      eval TARGET_FOLDER=$OPTARG
      if [ -z $TARGET_FOLDER ]; then
        echo "Missing -t parameter key. No project will be created." 
        exit 1
      fi
      ;;
    p)
      PROJECT_NAME=$OPTARG
      if [ -z $PROJECT_NAME ]; then
        echo "No project name has been set. Project will be created with last folder name."
      fi
      ;;
    v)
      SCALA_VERSION=$OPTARG
      ;;
    h)
      usage
      ;;
    i)
      IDEA_INIT=YES
      ;;
  esac
done

echo $TARGET_FOLDER

if [ -z $PROJECT_NAME ]; then
  PROJECT_NAME=`extract_folder_name $TARGET_FOLDER`
else
  TARGET_FOLDER=${TARGET_FOLDER}/${PROJECT_NAME}
fi

mkdir -p ${TARGET_FOLDER}

cd ${TARGET_FOLDER}

initialize_folder_structure
build_sbt > ${TARGET_FOLDER}/build.sbt
plugins_sbt > ${TARGET_FOLDER}/project/plugins.sbt

if [ -n "${IDEA_INIT}" ]; then
  sbt << INIT_IDEA
    gen-idea
INIT_IDEA
fi

exit 0