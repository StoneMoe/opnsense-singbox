<style>
    .config-textarea {
        width: 100vw;
        max-width: 50vw;
        min-height: 400px;
        font-family: "Courier New", Courier, monospace;
        margin-bottom: 10px;
    }

    .status-message {
        display: none;
        margin-top: 10px;
        padding: 10px;
        border-radius: 4px;
    }

    .status-message.success {
        border-color: #d6e9c6;
        color: #3c763d;
    }

    .status-message.error {
        border-color: #ebccd1;
        color: #a94442;
    }

    .log-container {
        font-family: "Courier New", Courier, monospace;
        font-size: 12px;
        padding: 10px;
        border-radius: 4px;
        max-height: 300px;
        overflow-y: auto;
        white-space: pre-wrap;
        word-wrap: break-word;
    }

    .version-badge {
        display: inline-block;
        padding: 2px 8px;
        border-radius: 3px;
        font-size: 12px;
        margin-left: 10px;
        max-width: 300px;
        overflow: hidden;
        text-overflow: ellipsis;
        white-space: nowrap;
        vertical-align: middle;
    }

    .panel-section {
        margin-top: 20px;
        padding: 15px;
        border: 1px solid #ddd;
        border-radius: 4px;
    }

    .panel-section h4 {
        margin-top: 0;
        margin-bottom: 15px;
        padding-bottom: 10px;
        border-bottom: 1px solid #eee;
    }

    .binary-row {
        display: flex;
        align-items: center;
        justify-content: space-between;
        padding: 8px 0;
        border-bottom: 1px solid #eee;
    }

    .binary-row:last-child {
        border-bottom: none;
    }

    .binary-info {
        display: flex;
        align-items: center;
    }

    .binary-name {
        font-weight: bold;
        min-width: 100px;
    }

    .log-controls {
        display: flex;
        align-items: center;
        gap: 10px;
        margin-bottom: 10px;
    }

    .output-modal-content {
        font-family: "Courier New", Courier, monospace;
        font-size: 12px;
        white-space: pre-wrap;
        padding: 10px;
        border-radius: 4px;
        max-height: 400px;
        overflow-y: auto;
    }

    .binary-actions {
        display: flex;
        gap: 5px;
    }

    .upload-input {
        display: none !important;
    }
</style>

{{ partial("layout_partials/base_form",['fields':generalForm,'id':'frm_GeneralSettings'])}}

<div class="row">
    <div class="col-md-12">
        <hr />
        <button class="btn btn-primary" id="saveAct" type="button">
            {{ lang._('Save') }}
        </button>
        <button class="btn btn-info" id="testAct" type="button">
            <i class="fa fa-check-circle"></i> {{ lang._('Test Config') }}
        </button>
        <div id="saveMsg" class="status-message"></div>
    </div>
</div>

<!-- Binary Management Section -->
<div class="panel-section">
    <h4><i class="fa fa-cube"></i> {{ lang._('Binary Management') }}</h4>
    <div id="binarySection">
        <div class="binary-row">
            <div class="binary-info">
                <span class="binary-name">sing-box</span>
                <span class="version-badge" id="singboxVersion">Loading...</span>
            </div>
            <div class="binary-actions">
                <button class="btn btn-sm btn-warning" id="updateSingboxBtn" type="button">
                    <i class="fa fa-download"></i> {{ lang._('Update') }}
                </button>
                <button class="btn btn-sm btn-default" id="uploadSingboxBtn" type="button">
                    <i class="fa fa-upload"></i> {{ lang._('Upload') }}
                </button>
                <input type="file" id="singboxFileInput" class="upload-input" accept="*">
            </div>
        </div>
        <div class="binary-row">
            <div class="binary-info">
                <span class="binary-name">hev-socks5-tunnel</span>
                <span class="version-badge" id="tun2socksVersion" title="">Loading...</span>
            </div>
            <div class="binary-actions">
                <button class="btn btn-sm btn-warning" id="updateTun2socksBtn" type="button">
                    <i class="fa fa-download"></i> {{ lang._('Update') }}
                </button>
                <button class="btn btn-sm btn-default" id="uploadTun2socksBtn" type="button">
                    <i class="fa fa-upload"></i> {{ lang._('Upload') }}
                </button>
                <input type="file" id="tun2socksFileInput" class="upload-input" accept="*">
            </div>
        </div>
    </div>
</div>

<!-- Log Viewer Section -->
<div class="panel-section">
    <h4><i class="fa fa-file-text-o"></i> {{ lang._('Logs') }}</h4>
    <div class="log-controls">
        <button class="btn btn-sm btn-default" id="refreshLogBtn" type="button">
            <i class="fa fa-refresh"></i> {{ lang._('Refresh') }}
        </button>
        <label class="checkbox-inline">
            <input type="checkbox" id="autoRefreshLog"> {{ lang._('Auto-refresh') }}
        </label>
    </div>
    <div class="log-container" id="logContent">{{ lang._('Click Refresh to load logs...') }}</div>
</div>

<!-- Output Modal -->
<div class="modal fade" id="outputModal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal"><span>&times;</span></button>
                <h4 class="modal-title" id="outputModalTitle">Output</h4>
            </div>
            <div class="modal-body">
                <div class="output-modal-content" id="outputModalContent"></div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default" data-dismiss="modal">{{ lang._('Close') }}</button>
            </div>
        </div>
    </div>
</div>

<script>
    $(document).ready(function () {
        var data_get_map = { 'frm_GeneralSettings': "/api/singbox/settings/get" };
        var logRefreshInterval = null;

        function showMessage(message, isError) {
            $("#saveMsg")
                .removeClass("success error")
                .addClass(isError ? "error" : "success")
                .html(message)
                .fadeIn()
                .delay(3000)
                .fadeOut();
        }

        function showOutputModal(title, content) {
            $("#outputModalTitle").text(title);
            $("#outputModalContent").text(content);
            $("#outputModal").modal("show");
        }

        function loadVersions() {
            $.ajax({
                url: "/api/singbox/settings/versions",
                type: "GET",
                dataType: "json",
                success: function (data) {
                    $("#singboxVersion").text(data.singbox || "Unknown");
                    $("#tun2socksVersion").text(data.tun2socks || "Unknown").attr("title", data.tun2socks || "");
                },
                error: function () {
                    $("#singboxVersion").text("Error");
                    $("#tun2socksVersion").text("Error");
                }
            });
        }

        function loadLogs() {
            $.ajax({
                url: "/api/singbox/settings/log",
                type: "GET",
                dataType: "json",
                success: function (data) {
                    if (data.result === "ok") {
                        var logContent = data.log || "No logs available";
                        $("#logContent").text(logContent);
                        // Auto-scroll to bottom
                        var logContainer = document.getElementById("logContent");
                        logContainer.scrollTop = logContainer.scrollHeight;
                    } else {
                        $("#logContent").text("Error loading logs");
                    }
                },
                error: function () {
                    $("#logContent").text("Error loading logs");
                }
            });
        }

        function toggleAutoRefresh() {
            if ($("#autoRefreshLog").is(":checked")) {
                loadLogs();
                logRefreshInterval = setInterval(loadLogs, 3000);
            } else {
                if (logRefreshInterval) {
                    clearInterval(logRefreshInterval);
                    logRefreshInterval = null;
                }
            }
        }

        // Initial load
        mapDataToFormUI(data_get_map).done(function (data) {
            formatTokenizersUI();
            $('.selectpicker').selectpicker('refresh');
        });

        loadVersions();

        // Save button
        $("#saveAct").click(function () {
            $("#saveAct").prop('disabled', true);
            saveFormToEndpoint("/api/singbox/settings/set", 'frm_GeneralSettings', function (data) {
                $("#saveAct").prop('disabled', false);
                if (data.result && data.result === "saved") {
                    showMessage("Saved", false);
                } else {
                    showMessage("Save failed: " + (data.error || "Unknown error"), true);
                }
            });
        });

        // Test config button
        $("#testAct").click(function () {
            var config = $("#singbox\\.general\\.config").val();
            if (!config || config.trim() === "") {
                showMessage("Configuration is empty", true);
                return;
            }

            $("#testAct").prop('disabled', true);
            $.ajax({
                url: "/api/singbox/settings/test",
                type: "POST",
                dataType: "json",
                data: { config: config },
                success: function (data) {
                    $("#testAct").prop('disabled', false);
                    if (data.result === "ok") {
                        var output = data.output || "";
                        if (output === "" || output.toLowerCase().indexOf("error") === -1) {
                            showMessage("Configuration is valid!", false);
                        } else {
                            showOutputModal("Configuration Error", output);
                        }
                    } else {
                        showMessage("Test failed: " + (data.error || "Unknown error"), true);
                    }
                },
                error: function () {
                    $("#testAct").prop('disabled', false);
                    showMessage("Test request failed", true);
                }
            });
        });

        // Update singbox button
        $("#updateSingboxBtn").click(function () {
            if (!confirm("Update sing-box to the latest version? This will restart the service if running.")) {
                return;
            }
            var btn = $(this);
            btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Updating...');
            $.ajax({
                url: "/api/singbox/settings/updateSingbox",
                type: "POST",
                dataType: "json",
                success: function (data) {
                    btn.prop('disabled', false).html('<i class="fa fa-download"></i> Update');
                    if (data.result === "ok") {
                        showOutputModal("Update sing-box", data.output || "Update completed");
                        loadVersions();
                    } else {
                        showMessage("Update failed: " + (data.error || "Unknown error"), true);
                    }
                },
                error: function () {
                    btn.prop('disabled', false).html('<i class="fa fa-download"></i> Update');
                    showMessage("Update request failed", true);
                }
            });
        });

        // Update tun2socks button
        $("#updateTun2socksBtn").click(function () {
            if (!confirm("Update hev-socks5-tunnel to the latest version? This will restart the service if running.")) {
                return;
            }
            var btn = $(this);
            btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Updating...');
            $.ajax({
                url: "/api/singbox/settings/updateTun2socks",
                type: "POST",
                dataType: "json",
                success: function (data) {
                    btn.prop('disabled', false).html('<i class="fa fa-download"></i> Update');
                    if (data.result === "ok") {
                        showOutputModal("Update hev-socks5-tunnel", data.output || "Update completed");
                        loadVersions();
                    } else {
                        showMessage("Update failed: " + (data.error || "Unknown error"), true);
                    }
                },
                error: function () {
                    btn.prop('disabled', false).html('<i class="fa fa-download"></i> Update');
                    showMessage("Update request failed", true);
                }
            });
        });

        // Refresh log button
        $("#refreshLogBtn").click(function () {
            loadLogs();
        });

        // Auto-refresh toggle
        $("#autoRefreshLog").change(function () {
            toggleAutoRefresh();
        });

        // Upload singbox button
        $("#uploadSingboxBtn").click(function () {
            $("#singboxFileInput").click();
        });

        $("#singboxFileInput").change(function () {
            var file = this.files[0];
            if (!file) return;

            if (!confirm("Upload and install this file as the sing-box binary?\n\nFile: " + file.name)) {
                $(this).val('');
                return;
            }

            var formData = new FormData();
            formData.append('file', file);

            var btn = $("#uploadSingboxBtn");
            btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Uploading...');

            $.ajax({
                url: "/api/singbox/settings/uploadSingbox",
                type: "POST",
                data: formData,
                processData: false,
                contentType: false,
                dataType: "json",
                success: function (data) {
                    btn.prop('disabled', false).html('<i class="fa fa-upload"></i> Upload');
                    if (data.result === "ok") {
                        showOutputModal("Upload sing-box", data.output || "Upload completed");
                        loadVersions();
                    } else {
                        showMessage("Upload failed: " + (data.error || "Unknown error"), true);
                    }
                },
                error: function () {
                    btn.prop('disabled', false).html('<i class="fa fa-upload"></i> Upload');
                    showMessage("Upload request failed", true);
                }
            });

            $(this).val('');
        });

        // Upload tun2socks button
        $("#uploadTun2socksBtn").click(function () {
            $("#tun2socksFileInput").click();
        });

        $("#tun2socksFileInput").change(function () {
            var file = this.files[0];
            if (!file) return;

            if (!confirm("Upload and install this file as the hev-socks5-tunnel binary?\n\nFile: " + file.name)) {
                $(this).val('');
                return;
            }

            var formData = new FormData();
            formData.append('file', file);

            var btn = $("#uploadTun2socksBtn");
            btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> Uploading...');

            $.ajax({
                url: "/api/singbox/settings/uploadTun2socks",
                type: "POST",
                data: formData,
                processData: false,
                contentType: false,
                dataType: "json",
                success: function (data) {
                    btn.prop('disabled', false).html('<i class="fa fa-upload"></i> Upload');
                    if (data.result === "ok") {
                        showOutputModal("Upload hev-socks5-tunnel", data.output || "Upload completed");
                        loadVersions();
                    } else {
                        showMessage("Upload failed: " + (data.error || "Unknown error"), true);
                    }
                },
                error: function () {
                    btn.prop('disabled', false).html('<i class="fa fa-upload"></i> Upload');
                    showMessage("Upload request failed", true);
                }
            });

            $(this).val('');
        });

        // Beautify textarea
        $("#singbox\\.general\\.config").addClass('config-textarea');
    });
</script>