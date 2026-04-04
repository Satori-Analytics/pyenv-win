from setuptools import setup, find_packages
from os import path
from io import open

here = path.abspath(path.dirname(__file__))

with open(path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

with open(path.join(here, '.version'), encoding='utf-8') as f:
    version = f.read()

setup(
    name = 'pyenv-win',
    version = version,
    description = "pyenv lets you easily switch between multiple versions of Python. It's simple, unobtrusive, and follows the UNIX tradition of single-purpose tools that do one thing well.",
    long_description = long_description,
    long_description_content_type = 'text/markdown',
    url = 'https://github.com/satori-analytics/pyenv-win.git',
    author = 'Nikolas Demiridis',
    author_email = 'nikolas.demiridis@satorianalytics.com',
    classifiers = [
        'Development Status :: 5 - Production/Stable',
        'Intended Audience :: Developers',
        'Topic :: Software Development :: Build Tools',
        'License :: OSI Approved :: MIT License',
        'Operating System :: Microsoft :: Windows',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Programming Language :: Python :: 3.11',
        'Programming Language :: Python :: 3.12',
    ],
    keywords = 'pyenv for windows, multiple versions of python',
    packages = find_packages(
        exclude=['tests']
    ),
    package_dir = {
        'pyenv-win': 'pyenv-win'
    },
    package_data = {
        'pyenv-win': 
        [
            'bin/pyenv.ps1',
            'bin/pyenv.cmd',
            'bin/pyenv',
            'bin/pyenv.shim',
            'lib/*.ps1',
            'libexec/*.ps1',
            '../.version', 
            '.versions_cache.xml'
        ]
    },
)
