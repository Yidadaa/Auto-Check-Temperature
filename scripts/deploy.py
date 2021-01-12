import os, json
from datetime import datetime

def get_folder_abs_path():
  """Get absolute path of the script folder."""
  file_path = os.path.abspath(__file__)
  folder_path = os.path.dirname(file_path)
  return folder_path

def depoly():
  """Run depoly."""
  script_folder = get_folder_abs_path()
  asset_folder = os.path.join(script_folder, '../assets')
  version_path = os.path.join(asset_folder, 'version.json')
  spec_path = os.path.join(script_folder, '../pubspec.yaml')

  # print last version info
  with open(version_path, 'r', encoding='utf-8') as fp:
    last_version_info = json.load(fp)
  print('Last Version Info:')
  print(last_version_info)

  # format field
  last_version_info['date'] = datetime.fromtimestamp(last_version_info['ts'])
  last_version_info['ver'] = float(last_version_info['ver'])

  # latest changes
  changes = os.popen('git log --pretty=oneline --abbrev-commit {}..'.format(last_version_info['hash']))
  print('\nLatest Changes:')
  print(changes.read())

  # new version
  now_date = datetime.now()
  new_version = {
    'ver': '{:.2f}'.format(last_version_info['ver'] + 0.1),
    'publishDate': now_date.strftime('%Y-%m-%d %H:%M:%S'),
    'ts': now_date.timestamp(),
    'description': [],
    'hash': os.popen('git log --pretty=oneline --abbrev-commit -1').read()[:7]
  }
  print('\nPlease Enter Release Info: (press q to finsh)')
  line = ''
  while line != 'q':
    if line: new_version['description'].append(line)
    line = input()

  print('\nNew Version Info:')
  print(new_version)

  # update yaml file
  with open(spec_path, 'r') as fp:
    spec_content = fp.read().split('\n')

  if input('\nConfirm(Y/n): ').upper() != 'N':
    with open(version_path, 'w', encoding='utf-8') as fp:
      json.dump(new_version, fp)
    with open(spec_path, 'w') as fp:
      new_spec_content = []
      for line in spec_content:
        if line.startswith('version:'):
          line = 'version: {:.2f}.0'.format(new_version['ver'])
        new_spec_content.append(line)
      fp.write('\n'.join(spec_content))
    print('Done.')
  else:
    print('Canceled.')

if __name__ == "__main__":
  depoly()