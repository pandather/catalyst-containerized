#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import tomli
import io
import os

def optionsCopy(options):
    return {key: value[:] for key, value in options.items()}

def printTOMLHelper(toml, level):
    for key in list(toml.keys()):
        output = "{} = {}".format(key, toml[key])
        leading = "> "
        for i in range(level):
            leading = "-{}".format(leading)
        if type(toml[key]) is dict:
            output = "{}:".format(key)
        print("{}{}".format(leading, output))
        if type(toml[key]) is dict:
            printTOMLHelper(toml[key], level + 1)

def printTOML(toml):
    printTOMLHelper(toml, 0)

def prepareTarget(name, prefix, subDict, options, specfile):
    #TODO: Figure this out.
    if len(prefix):
        prefix = '{}/'.format(prefix)
    if 'target' in options.keys() and name != 'snapshot':
        target = options['target']
        ind = target.index('stage')
        if ind != 0:
            ind = ind - 1
        target = target[:ind]
        if 'version' in options.keys():
            options['version'] = '{}-{}'.format(target, options['version'])
        elif 'version' in subDict.keys():
            subDict['version'] = '{}-{}'.format(target, subDict['version'])
    elif 'target' in subDict.keys() and name != 'snapshot':
        target = subDict['target']
        ind = target.index('stage')
        if ind != 0:
            ind = ind - 1
        target = target[:ind]
        if len(target) == 0:
            target = 'openrc'
        if 'version' in options.keys():
            options['version'] = '{}-{}'.format(target, options['version'])
        elif 'version' in subDict.keys():
            subDict['version'] = '{}-{}'.format(target, subDict['version'])
    
    for option, value in options.items():
        if option == 'kernel_order':
            option = 'kernel'
            if len(value) > 1:
                value = ''.join([str(item) + ' ' for item in value]).strip()
        if name == '':
            newPrefix = '{}{}'.format('boot/' if str(option) == 'kernel' else prefix, option)
        else:
            newPrefix = option
        if type(value) is dict:
            prepareTarget('', newPrefix, value, {}, specfile)
        if type(value) is list:
            spacing = '{}: '.format(newPrefix)
            if len(value) > 1:
                spacing = '\t'
                specfile.write('{}:'.format(newPrefix))
                specfile.write(os.linesep)
            for x in range(len(value)):
                if type(value[x]) is list:
                    specfile.write('{}{}|{}'.format(spacing, value[x][0], value[x][1]))
                    specfile.write(os.linesep)
                else:
                    specfile.write('{}{}'.format(spacing, value[x]))
                    specfile.write(os.linesep)
            #print('{}: {}'.format(option, valueString))
        else:
            specfile.write('{}: {}'.format(newPrefix, value))
            specfile.write(os.linesep)
    for option, value in subDict.items():
        if option == 'kernel_order':
            option = 'kernel'
            if len(value) > 1:
                value = ''.join([str(item) + ' ' for item in value]).strip()
        if name == '':
            newPrefix = '{}{}'.format(prefix, option)
        else:
            newPrefix = '{}{}'.format('boot/' if str(option) == 'kernel' else prefix, option)
        if type(value) is list:
            if len(value) == 0:
                continue
            spacing = '{}: '.format(newPrefix)
            if len(value) > 1:
                spacing = '\t'
                specfile.write('{}:'.format(newPrefix))
                specfile.write(os.linesep)
            for x in range(len(value)):
                if type(value[x]) is list:
                    specfile.write('{}{}|{}'.format(spacing, value[x][0], value[x][1]))
                    specfile.write(os.linesep)
                else:
                    specfile.write('{}{}'.format(spacing, value[x]))
                    specfile.write(os.linesep)
        elif type(value) is dict:
            if len(value) == 0:
                continue
            prepareTarget('', newPrefix, value, {}, specfile)
        else:
            specfile.write('{}: {}'.format(newPrefix, value))
            specfile.write(os.linesep)
    
def preparePrefix(prefix, subDict, options):
    if type(subDict) is not dict:
        print('Tried to prepare an incorrect prefix')
        exit(1)
    subtargets = {}
    for key, value in subDict.items():
        if type(value) is dict:
            subtargets[key] = value
        else:
            options[key] = value
    stageTargets = subtargets.keys().ordered()
    print(stageTargets)
    for target, target_opts in subtargets.items():
        filename = ''
        if prefix == 'iso':
            prefix = 'livecd'
        if prefix == 'default':
            prefix = ''
        if len(prefix) and prefix != 'default':
            filename = '{}-{}.spec'.format(target, prefix)
        else:
            filename = '{}.spec'.format(target)
        with open(filename, 'w') as specfile:
            prepareTarget(target, prefix, target_opts, optionsCopy(options), specfile)

try:
    with open('ppc.build', encoding='utf-8') as f:
        tomlDict = tomli.load(f)
        #print(toml_dict)
        if tomlDict['snapshot'] != None and tomlDict['snapshot']['snapshot'] != None:
            with open('snapshot.spec', 'w') as specfile:
                prepareTarget('snapshot', 'default', tomlDict['snapshot'], {}, specfile)
        prefixes = {}
        global_opts = {}
        for prefix, prefixOptions in tomlDict['build'].items():
            if type(prefixOptions) is dict:
                prefixes[prefix] = prefixOptions
            else:
                global_opts[prefix] = prefixOptions
        for prefix, prefixOptions in prefixes.items():
            preparePrefix(prefix, prefixOptions, optionsCopy(global_opts))

except tomli.TOMLDecodeError:
    print('Configuration file is not a valid TOML file.')
