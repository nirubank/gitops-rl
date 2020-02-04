#!/bin/bash

LANG=C

echo ""
echo "*****************************************************"
echo "**                                                 **"
echo "**  Demo Setup:                                    **"
echo "**    - Branch, rename files, commit, push.        **"
echo "**                                                 **"
echo "*****************************************************"

GIT_URL=`git config --get remote.origin.url`
GIT_URL="$GIT_URL"

GIT_REF=`git rev-parse --abbrev-ref HEAD`

read -p "Use repository $GIT_URL (y/n)? " useremote
if [[ "$useremote" == "n" ]]; then
    read -p "Git repository: "  GIT_URL
fi
echo "Using repository $GIT_URL"


read -p "Use branch $GIT_REF (y/n)?" usebranch
if [[ "$usebranch" == "n" ]]; then
    read -p "Repository branch: " GIT_REF
fi
echo "Using branch $GIT_REF"

read -p 'Base apps url (e.g. apps.ocp.pitt.ca): ' APPS_BASE_URL
read -p 'Quay read/write username: ' quayrwuser
read -p 'Quay read/write email: ' quayrwemail
read -sp 'Quay read/write password: ' quayrwpass
echo ""
read -p 'Quay read-only username: ' quayrouser
read -p 'Quay read-only email: ' quayroemail
read -sp 'Quay read-only password: ' quayropass
echo ""

echo "Setting git branch."
if [[ "$GIT_REF" == "master" ]]; then
    echo "Using master branch."
else
    echo "Creating branch $GIT_REF."
    git checkout -b $GIT_REF
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    FIND_ROUTE_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/apps\\.dc1\\.com/'
    FIND_REPO_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/git\\.url\\.git/'
    FIND_BRANCH_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'\' \'s/targetRevision:\ master/targetRevision:\ '
else
    FIND_ROUTE_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'s/apps\\.dc1\\.com/'
    FIND_REPO_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'s/git\\.url\\.git/'
    FIND_BRANCH_PREFIX=$'find $PWD \\( -type d -name .git -prune \\) -o -type f -print0 | xargs -0 sed -i \'s/targetRevision:\ master/targetRevision:\ '
fi

FIND_SUFFIX=$'/g\''

ROUTE=$(sed 's/\./\\./g' <<< $APPS_BASE_URL)
REPO=$(sed 's/\./\\./g' <<< $GIT_URL)
REPO=$(sed 's/\//\\\//g' <<< $REPO)
BRANCH=$(sed 's/\./\\./g' <<< $GIT_REF)

FIND_AND_REPLACE_ROUTE="$FIND_ROUTE_PREFIX$ROUTE$FIND_SUFFIX"
FIND_AND_REPLACE_REPO="$FIND_REPO_PREFIX$REPO$FIND_SUFFIX"
FIND_AND_REPLACE_BRANCH="$FIND_BRANCH_PREFIX$BRANCH$FIND_SUFFIX"

echo "Replacing Routes... "
echo "$FIND_AND_REPLACE_ROUTE"
echo "Replacing git repos..."
echo "$FIND_AND_REPLACE_REPO"
echo "Replacing git branches..."
echo "$FIND_AND_REPLACE_BRANCH"
echo ""

eval $FIND_AND_REPLACE_ROUTE
eval $FIND_AND_REPLACE_REPO
eval $FIND_AND_REPLACE_BRANCH
echo ""

echo "Creting Sealed Secrets."
oc create secret docker-registry quay-cicd-secret --docker-server=quay.io --docker-username="$quayrwuser" --docker-password="$quayrwpass" --docker-email="$quayrwemail" -n cicd -o json --dry-run | kubeseal --cert ~/bitnami/publickey.pem > gitops/resources/cicd/builds/quay-cicd-sealedsecret.json
oc create secret docker-registry quay-pull-secret --docker-server=quay.io --docker-username="$quayrouser" --docker-password="$quayropass" --docker-email="$quayroemail" -n petclinic-dev -o json --dry-run | kubeseal --cert ~/bitnami/publickey.pem > gitops/resources/products/petclinic/bases/quay-pull-sealedsecret.json

# Need to write this one to disk temporarily in order to add a label to it.
mkdir -p ~/tmp/tmpsecrets
oc create secret generic quay-creds-secret --from-literal="username=$quayrwuser" --from-literal="password=$quayrwpass" -n cicd -o yaml --dry-run > ~/tmp/tmpsecrets/quay-creds.yaml
printf "  labels:\n    credential.sync.jenkins.openshift.io: \"true\"\n" >> ~/tmp/tmpsecrets/quay-creds.yaml
kubeseal --cert ~/bitnami/publickey.pem < ~/tmp/tmpsecrets/quay-creds.yaml > gitops/resources/cicd/builds/quay-creds-sealedsecret.json
rm -rf ~/tmp/tmpsecrets

echo "Adding/Committing/Pushing sealed secrets to the $GIT_REF branch of $GIT_URL"
git add --all
git commit -m "Updated routes and git repo urls/branches."
git push origin $GIT_REF
echo "Pushed!"

echo "Done!"
