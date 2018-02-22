FROM codefresh/plugin-helm:2.8.0
COPY cf-helm-export.sh /
CMD ["/cf-helm-export.sh"]
