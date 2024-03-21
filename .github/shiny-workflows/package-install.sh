if [ "$RUNNER_OS" == "macOS" ]; then
  R -e 'install.packages("arrow", type="source")'
fi
