#!/bin/bash -xe

systemctl --user daemon-reload
systemctl --user enable cliphist-thumbs-cleanup.timer
systemctl --user start cliphist-thumbs-cleanup.timer
systemctl --user status cliphist-thumbs-cleanup.timer
systemctl --user status cliphist-thumbs-cleanup.service
