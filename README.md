# ocp-bg-pipelines


## Instalación
Para instalar basta con clonar el repositorio

## Despliege en OpenShift
* loguearse en OCP mediante el comando oc login
* ejecutar el comando $ ./pipeline.sh

**Nota:** Dentro del archivo pipeline.sh existen dos variables:
* VERSION="v2"
* VERSION_ANT="v1"

VERSION define la version nueva de creacion
VERSION_ANT define la version a borrar en el proceso de limpiado
