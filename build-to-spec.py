#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import tomli
import io
import os

INCORRECT_PREFIX_ERROR = 1
INVALID_STAGE_NUM_ERROR = 2
OPTION_NOT_FOUND_ERROR = 3
PREFIX_NOT_FOUND_ERROR = 4
STAGE_TREE_ERROR = 5

optionsToRemove = ['arch', 'skip']

specOptionList = ['subarch', 'target', 'version_stamp', 'rel_type', 'profile', 'snapshot', 'source_subpath', 'distcc_hosts', 'portage_confdir', 'portage_overlay', 'pkgcache_path']

defaultStageTarget = 'openrc'

targetStages = {}
rootNodes = []
def place_subtarget(potential_target, subtarget):
    if subtarget.generated_source_sp == potential_target.generated_output_sp:
        subtarget.source_sp = potential_target.output_sp
        potential_target.subtargets.append(subtarget)
        subtarget.parent = potential_target
        return True
    else:
        for potential_subtarget in potential_target.subtargets:
            if place_subtarget(potential_subtarget, subtarget):
                return True
    print('Unable to build stage tree.')
    exit(STAGE_TREE_ERROR)

def getNodeLevel(node):
    if node.parent == None:
        return 0
    else:
        return 1 + getNodeLevel(node.parent)
                
class TargetSet:
    def writeOut(self):
        level = getNodeLevel(self)
        filename = '{:02d}-{}'.format(getNodeLevel(self), self.target.filename)
        with open(filename, 'w') as file:
            file.write(str(self.target))
        for subtarget in self.subtargets:
            subtarget.writeOut()

    def __repr__(self):
        spacing=''
        while len(spacing) < getNodeLevel(self):
            spacing = ' {}'.format(spacing)
        outstring = ''
        outstring = '{}{} -> {}{}'.format(spacing, self.source_sp, self.output_sp, os.linesep)
        for subtarget in self.subtargets:
            outstring = '{}{}'.format(outstring, str(subtarget))
        return outstring

    def __init__(self, target):
        self.parent = None
        self.subtargets = []
        self.target = target
        self.name = self.target.target
        ind = self.name.index('stage')
        if ind < 0:
            print("Invalid stage, must be 10 > stage# > 0.")
            exit(INVALID_STAGE_NUM_ERROR)
        elif ind > 0:
            self.prefix = self.name[:ind - 1]
            self.stage = int(self.name[ind + len('stage'):] )
        else:
            self.prefix = ''
            self.stage = int(self.name[ind + len('stage'):])
        basic_version = self.target.version
        if basic_version == '@TIMESTAMP@':
            basic_version = 'latest'
        if self.target.prefix == 'livecd':
            self.filled_version = '-{}-{}'.format(self.target.subarch, basic_version)
            self.unfilled_version = '-{}-{}'.format(self.target.subarch, self.target.version)
        else:
            self.filled_version = '-{}-{}-{}'.format(self.target.subarch, self.target.prefix, basic_version)
            self.unfilled_version = '-{}-{}-{}'.format(self.target.subarch, self.target.prefix, self.target.version)
        self.stageIdent = self.name[:ind + len('stage')]
        ref = None
        self.source_sp = self.target.source_subpath
        self.generated_source_sp = self.source_sp
        if self.stage > 1:
            self.generated_source_sp = '{}/{}{}{}'.format(self.target.rel_type, self.stageIdent, str(self.stage - 1), self.filled_version)
            self.source_sp = '{}/{}{}{}'.format(self.target.rel_type, self.stageIdent, str(self.stage - 1), self.unfilled_version)
        self.generated_output_sp = '{}/{}{}{}'.format(self.target.rel_type, self.stageIdent, str(self.stage), self.filled_version)
        self.output_sp = '{}/{}{}{}'.format(self.target.rel_type, self.stageIdent, str(self.stage), self.unfilled_version)
        if self.target.source_subpath not in targetStages.keys():
            targetStages[self.target.source_subpath] = self
        else:
            place_subtarget(targetStages[self.target.source_subpath], self)


    def process_skipped_stages(self):
        for subtarget in self.subtargets:
            skipped = subtarget.target.skip
            if skipped:
                for newsubtarget in subtarget.subtargets:
                    newsubtarget.generated_source_sp = self.generated_output_sp
                    newsubtarget.source_sp = self.output_sp
                    newsubtarget.parent = self
            if skipped:
                for newsubtarget in subtarget.subtargets:
                    self.subtargets.append(newsubtarget)
                self.subtargets.remove(subtarget)
        for subtarget in self.subtargets:
            subtarget.target.options['source_subpath'] = self.output_sp
            subtarget.process_skipped_stages()

def findOption(target, optionName):
    if optionName in target.options.keys():
        option = target.options[optionName]
    elif optionName in target.subdirectories.keys():
        option = target.subdirectories[optionName]
    elif optionName == 'skip':
        return False
    else:
        print('FATAL ERROR: Option \'' + optionName + '\' not found in target.')
        exit(OPTION_NOT_FOUND_ERROR)
    return option

def subdirectoriesRepr(dirPrefix, subdirs):
    outstring = ''
    for directory, entry in subdirs.items():
        if directory == 'kernel_order':
            directory = 'kernel'
            entry = ' '.join(entry)
        newPrefix = dirPrefix
        if directory == 'kernel':
            newPrefix = 'boot/'
        if directory in specOptionList:
            newPrefix = ''
        if directory in optionsToRemove:
            continue
        newPrefix = '{}{}'.format(newPrefix, directory)
        if type(entry) is list:
            if len(entry) == 0:
                continue
            spacing = '{}:\t'.format(newPrefix)
            if len(entry) > 1:
                spacing = '\t'
                outstring = '{}{}:{}'.format(outstring, newPrefix, os.linesep)
            for x in range(len(entry)):
                if type(entry[x]) is list:
                    outstring = '{}{}{}{}'.format(outstring, spacing, '|'.join(entry[x]), os.linesep)
                else:
                    outstring = '{}{}{}{}'.format(outstring, spacing, entry[x], os.linesep)
        elif type(entry) is dict:
            if len(entry) == 0:
                continue
            outstring = '{}{}'.format(outstring, subdirectoriesRepr('{}/'.format(newPrefix), entry))
        else:
            outstring = '{}{}:\t{}{}'.format(outstring, newPrefix, entry, os.linesep)
    return outstring

class Target:
    def __getattr__(self, name):
        if name in self.__dict__.keys():
            return self.__dict__[name]
        return findOption(self, name)

    def __repr__(self):
        output = ''
        for option, value in self.options.items():
            if option == 'version':
                option = 'version_stamp'
                value = self.node.unfilled_version[2 + len(self.subarch):]
            if option in optionsToRemove:
                continue
            output = '{}{}:\t{}{}'.format(output, option, value, os.linesep)
        output = '{}{}'.format(output, subdirectoriesRepr(self.subpath, self.subdirectories))
        return output

    def __init__(self, subpath, prefix, options, subdirectories):
        self.subpath = subpath
        self.prefix = prefix
        self.options = optionsCopy(options)
        self.subdirectories = subdirectories
        subpath = True
        if self.prefix == self.rel_type:
            subpath = False
        if self.prefix == 'iso':
            self.prefix = 'livecd'
        elif self.prefix == 'default':
            self.prefix = defaultStageTarget
        elif prefix == '':
            exit(PREFIX_NOT_FOUND_ERROR)
        self.subpath = '{}/'.format(self.prefix)
        if not subpath:
            self.subpath = ''
        self.node = TargetSet(self)
        self.filename = self.target
        if self.prefix != 'livecd':
            self.filename = '{}-{}'.format(self.filename, self.prefix)
        self.filename = '{}.spec'.format(self.filename)
        
def optionsCopy(options):
    return {key: value[:] for key, value in options.items()}

def preparePrefix(prefix, subDict, options):
    if type(subDict) is not dict:
        print('Tried to prepare an incorrect prefix')
        exit(INCORRECT_PREFIX_ERROR)
    subtargets = {}
    for key, value in subDict.items():
        if type(value) is dict:
            subtargets[key] = value
        else:
            options[key] = value
    for target, target_opts in subtargets.items():
        filename = target
        option_path = prefix
        if len(option_path) > 0:
            option_path = '{}/'.format(option_path)
        Target(option_path, prefix, optionsCopy(options), target_opts)

try:
    with open('ppc.build', encoding='utf-8') as f:
        tomlDict = tomli.load(f)
        if tomlDict['snapshot'] != None and tomlDict['snapshot']['snapshot'] != None:
            with open('snapshot.spec', 'w') as specfile:
                 specfile.write(subdirectoriesRepr('', tomlDict['snapshot']))
        prefixes = {}
        global_opts = {}
        for prefix, prefixOptions in tomlDict['build'].items():
            if type(prefixOptions) is dict:
                prefixes[prefix] = prefixOptions
            else:
                global_opts[prefix] = prefixOptions
        for prefix, prefixOptions in prefixes.items():
            preparePrefix(prefix, prefixOptions, optionsCopy(global_opts))
        for target_name, target in targetStages.items():
            target.process_skipped_stages()
        printedOne = False
        for target_name, target in targetStages.items():
            target.writeOut()

except tomli.TOMLDecodeError:
    print('Configuration file is not a valid TOML file.')
