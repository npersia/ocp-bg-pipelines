VERSION="v2"
VERSION_ANT="v1"
TEMP_BASE="bg-base.yaml"


OCP="https://ocp-master.semperti.com:8443"
USER="npersia"
PASS="redhat"

APP_DEV="bg-dev-$VERSION"
APP_DEV_DISPLAY_NAME="Blue-Green desarrollo"

APP_QA="bg-qa-$VERSION"
APP_QA_DISPLAY_NAME="Blue-Green Qa"


APP_PROD="bg-prod-$VERSION"
APP_PROD_DISPLAY_NAME="Blue-Green prod"


APP_JENK="bg-jenkins-$VERSION"
APP_JENK_DISPLAY_NAME="Blue-Green jenkins"
APP_JENK_TEMPLATE="jenkins-template.yaml"


oc login $OCP -u $USER -p $PASS

oc delete project "bg-jenkins-$VERSION_ANT";oc delete project "bg-prod-$VERSION_ANT";oc delete project "bg-qa-$VERSION_ANT";oc delete project "bg-dev-$VERSION_ANT"


oc new-project $APP_DEV
oc new-project $APP_QA
oc new-project $APP_PROD
oc new-project $APP_JENK

cp "$APP_JENK_TEMPLATE" "$APP_JENK_TEMPLATE-tmp"
sed -i 's/APP_PROD/'$APP_PROD'/g' "$APP_JENK_TEMPLATE-tmp"
sed -i 's/APP_QA/'$APP_QA'/g' "$APP_JENK_TEMPLATE-tmp"

oc create -f "$APP_JENK_TEMPLATE-tmp" -n $APP_JENK


oc policy add-role-to-user edit system:serviceaccount:$APP_JENK:jenkins -n $APP_QA
oc policy add-role-to-user edit system:serviceaccount:$APP_JENK:jenkins -n $APP_PROD
oc policy add-role-to-group system:image-puller system:serviceaccounts:$APP_PROD -n $APP_QA

oc create -f $TEMP_BASE -n $APP_DEV
oc create -f $TEMP_BASE -n $APP_QA
oc expose svc bg -n $APP_DEV
oc expose svc bg -n $APP_QA

APP_QA_IMAGE=$(oc get is -o jsonpath={.items[0].status.dockerImageRepository} -n $APP_QA)
echo $APP_QA_IMAGE



oc create deploymentconfig bg-blue --image=$APP_QA_IMAGE:promoteToProd -n $APP_PROD -o yaml > salida-blue.yaml
oc delete deploymentconfig bg-blue -n $APP_PROD
sed -i 's/IfNotPresent/Always/g' "salida-blue.yaml"
oc create -f salida-blue.yaml -n $APP_PROD

oc create deploymentconfig bg-green --image=$APP_QA_IMAGE:promoteToProd -n $APP_PROD -o yaml > salida-green.yaml
oc delete deploymentconfig bg-green -n $APP_PROD
sed -i 's/IfNotPresent/Always/g' "salida-green.yaml"
oc create -f salida-green.yaml -n $APP_PROD

oc expose dc bg-blue --port=8080 -n $APP_PROD
oc expose svc bg-blue -n $APP_PROD
oc expose dc bg-green --port=8080 -n $APP_PROD
oc expose svc bg-green -n $APP_PROD


oc create -f routes.yaml -n $APP_PROD


rm salida-green.yaml salida-blue.yaml "$APP_JENK_TEMPLATE-tmp"
