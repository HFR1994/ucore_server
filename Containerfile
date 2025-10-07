# Stage 0: Context / Build scripts
FROM scratch AS ctx
COPY build_files /

# Stage 1: Base image
FROM ghcr.io/ublue-os/ucore-hci:stable-nvidia AS base

COPY --from=ctx /preset.sh /tmp/preset.sh
RUN chmod +x /tmp/preset.sh \
    && /tmp/preset.sh

# Optional: additional packages or modifications can go here
# RUN dnf install -y <your-packages> && dnf clean all

# Stage 2: JetBrains WebStorm
FROM base AS webstorm
COPY --from=ctx /jetbrains.sh /tmp/jetbrains.sh
RUN chmod +x /tmp/jetbrains.sh \
    && /tmp/jetbrains.sh WS WS

# Stage 3: JetBrains IntelliJ IDEA
FROM base AS idea
COPY --from=ctx /jetbrains.sh /tmp/jetbrains.sh
RUN chmod +x /tmp/jetbrains.sh \
    && /tmp/jetbrains.sh IIU IU

# Stage 4: JetBrains PyCharm
FROM base AS pycharm
COPY --from=ctx /jetbrains.sh /tmp/jetbrains.sh
RUN chmod +x /tmp/jetbrains.sh \
    && /tmp/jetbrains.sh PCP PY

# Stage 5: JetBrains CLion
FROM base AS clion
COPY --from=ctx /jetbrains.sh /tmp/jetbrains.sh
RUN chmod +x /tmp/jetbrains.sh \
    && /tmp/jetbrains.sh CL CL

# # Stage 6: JetBrains Gateway
# FROM base AS gateway
# COPY --from=ctx /jetbrains.sh /tmp/jetbrains.sh
# RUN chmod +x /tmp/jetbrains.sh \
#     && /tmp/jetbrains.sh GW GW

# Stage 7: Final image
FROM base AS final

# Copy installed IDEs from each stage
COPY --from=webstorm /opt/jetbrains/backends /opt/jetbrains/backends
COPY --from=idea /opt/jetbrains/backends /opt/jetbrains/backends
COPY --from=pycharm /opt/jetbrains/backends /opt/jetbrains/backends
COPY --from=clion /opt/jetbrains/backends /opt/jetbrains/backends

# Copy build scripts to final stage if needed
COPY --from=ctx / /ctx

# Run your original build.sh (for further modifications)
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh

# Lint / verify the final image
RUN bootc container lint
