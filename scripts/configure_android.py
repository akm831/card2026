import os,pathlib,json,re
sdk=os.environ['ANDROID_HOME'];java=os.environ['JAVA_HOME']
config=pathlib.Path(os.environ.get('XDG_CONFIG_HOME',str(pathlib.Path.home()/'.config')))/'godot'
config.mkdir(parents=True,exist_ok=True)
(config/'editor_settings-4.6.tres').write_text('[gd_resource type="EditorSettings" format=3]\n\n[resource]\nexport/android/android_sdk_path = '+json.dumps(sdk)+'\nexport/android/java_sdk_path = '+json.dumps(java)+'\n')
p=pathlib.Path('godot/export_presets.cfg');s=p.read_text();s=re.sub(r'version/code=\d+','version/code='+str(int(os.environ.get('GITHUB_RUN_NUMBER','1'))),s);p.write_text(s)
