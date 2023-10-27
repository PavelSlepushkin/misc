### 2.3 Traffic tapping
https://www.envoyproxy.io/docs/envoy/v1.12.0/configuration/http/http_filters/tap_filter.html 

1. Create EnvoyFilter - additional envoy configuration
```
k apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: tap-filter
  namespace: platform
spec:
  workloadSelector:
    labels:
      app: httpbin
  configPatches:
  - applyTo: HTTP_FILTER
    match:
      context: SIDECAR_INBOUND
      listener:
        portNumber: 80
        filterChain:
          filter:
            name: "envoy.filters.network.http_connection_manager"
            subFilter:
              name: "envoy.filters.http.router"
    patch:
      operation: INSERT_BEFORE
      value:
       name: envoy.filters.http.tap
       typed_config:
          "@type": "type.googleapis.com/envoy.extensions.filters.http.tap.v3.Tap"
          commonConfig:
            adminConfig:
              configId: test_config_id
EOF
```

```
cat - <<EOF > tap.yaml
config_id: test_config_id
tap_config:
  match_config:
    any_match: true
  output_config:
    sinks:
      - streaming_admin: {}
EOF
```

- k port-forward httpbin-.... 15000
- curl --data-binary "@tap.yaml" localhost:15000/tap
-  execute request to httpbin service
