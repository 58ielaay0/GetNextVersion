# GetNextVersion

# NexusUpload

This is a Github action which retrieve the last package version from a Nexus directory and increment it. The output of this action can be used to know the version to use for the next package to build.

The version in the package name need to be between - or _ or at the end of the file name (extension excluded). - and _ can't be used elsewhere in the filename.
Examples: 
- name-0.0.1.zip
- name-0.0.1-dev.zip
- name.subname_0.0.1_dev.zip

### Inputs (mandatory):
- env :
  - NEXUS_USER : username to connect to the Nexus server
  - NEXUS_PASSWORD : password to connect to the Nexus server
- with :
  - NexusURL : the base url of the Nexus server
  - Repository : the name of the repository where the packages to browse are located
  - RepositoryDirectory : the directory (component group) of the repository where the packages to browse are located

### Inputs (optional):
- with :
  - CommitHash : the github sha of the last commit. If provided, the 7 first characters will be added at the end of the returned version

### Output :
- nextversion : the version to use for the next package to upload on Nexus in the specified directory

### Example in the github action :

```yaml
- id: getNextVersion
  name: Get next package version
  uses: 58ielaay0/GetNextVersion@v0.1
  env:
    NEXUS_USER: ${{ secrets.NEXUS_USER }}
    NEXUS_PASSWORD: ${{ secrets.NEXUS_PASSWORD }}
  with:
    NexusURL: 'https://nexus.test.com'
    Repository: 'raw'
    RepositoryDirectory: 'test'
    CommitHash: '${{github.sha}}'
```

To use the output of the action in another step :

```yaml
${{ steps.getNextVersion.outputs.nextversion }}
```
