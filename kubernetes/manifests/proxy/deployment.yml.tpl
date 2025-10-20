apiVersion: apps/v1
kind: Deployment
metadata:
  name: proxy-deploy
  namespace: ${namespace}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: proxy-deploy
  template:
    metadata:
      labels:
        app: proxy-deploy
    spec:
      containers:
        - name: nginx-proxy
          image: nginx:latest
          ports:
            - containerPort: 80
              protocol: TCP
            - containerPort: 443
              protocol: TCP
            - containerPort: 25565
              protocol: TCP
            - containerPort: 7521
              protocol: TCP
            - containerPort: 5555
              protocol: TCP
            - containerPort: 6443
              protocol: TCP
          volumeMounts:
            - name: nginx-config-volume
              mountPath: /etc/nginx/nginx.conf
              subPath: nginx.conf
      volumes:
        - name: nginx-config-volume
          configMap:
            name: proxy-config
