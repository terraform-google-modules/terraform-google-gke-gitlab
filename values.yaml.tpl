# Values for gitlab/gitlab chart on GKE
global:
  edition: ce
  hosts:
    domain: ${DOMAIN}
    https: true
    externalIP: ${INGRESS_IP}
    ssh: ~

    gitlab:
      name: ${DOMAIN}

  ## doc/charts/globals.md#configure-ingress-settings
  ingress:
    configureCertmanager: true
    enabled: true
    tls:
      enabled: true

  ## doc/charts/globals.md#configure-postgresql-settings
  psql:
    password: 
      secret: gitlab-pg
      key: password
    host: ${DB_PRIVATE_IP}
    port: 5432
    username: gitlab
    database: gitlabhq_production

  redis:
    password:
      enabled: false
    host: ${REDIS_PRIVATE_IP}

  ## doc/charts/globals.md#configure-minio-settings
  minio:
    enabled: false

  ## doc/charts/globals.md#configure-appconfig-settings
  ## Rails based portions of this chart share many settings
  appConfig:
    ## doc/charts/globals.md#general-application-settings
    enableUsagePing: false

    ## doc/charts/globals.md#lfs-artifacts-uploads-packages
    backups:
      bucket: ${PROJECT_ID}-gitlab-backups
    lfs:
      bucket: ${PROJECT_ID}-git-lfs
      connection:
        secret: gitlab-rails-storage
        key: connection
    artifacts:
      bucket: ${PROJECT_ID}-gitlab-artifacts
      connection:
        secret: gitlab-rails-storage
        key: connection
    uploads:
      bucket: ${PROJECT_ID}-gitlab-uploads
      connection:
        secret: gitlab-rails-storage
        key: connection
    packages:
      bucket: ${PROJECT_ID}-gitlab-packages
      connection:
        secret: gitlab-rails-storage
        key: connection

    ## doc/charts/globals.md#pseudonymizer-settings
    pseudonymizer:
      bucket: ${PROJECT_ID}-gitlab-pseudo
      connection:
        secret: gitlab-rails-storage
        key: connection

certmanager-issuer:
  email: ${CERT_MANAGER_EMAIL}

prometheus:
  install: false

redis:
  enabled: false

gitlab:
  gitaly:
    persistence:
      size: 200Gi
      storageClass: "pd-ssd"
  task-runner:
    backups:
      objectStorage:
        backend: gcs
        config:
          secret: google-application-credentials
          key: gcs-application-credentials-file
          gcpProject: ${PROJECT_ID}

postgresql:
  install: false

gitlab-runner:
  install: ${GITLAB_RUNNER_INSTALL}
  rbac:
    create: true
  runners:
    locked: false
    cache:
      cacheType: gcs
      gcsBucketname: ${PROJECT_ID}-runner-cache
      secretName: google-application-credentials
      cacheShared: true

registry:
  enabled: true
  storage:
    secret: gitlab-registry-storage
    key: storage
    extraKey: gcs.json
