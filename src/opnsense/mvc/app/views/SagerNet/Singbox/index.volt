<style>
    /* Minimal custom CSS - only essential overrides */
    #singbox\.general\.config {
        min-height: 400px;
        font-family: "Courier New", Courier, monospace;
    }

    .log-container {
        max-height: 300px;
        overflow-y: auto;
        white-space: pre-wrap;
        word-wrap: break-word;
        font-family: "Courier New", Courier, monospace;
        font-size: 12px;
        background-color: #f5f5f5;
        border: 1px solid #ddd;
        border-radius: 4px;
        padding: 10px;
    }

    .output-modal-content {
        font-family: "Courier New", Courier, monospace;
        font-size: 12px;
        white-space: pre-wrap;
        background-color: #f5f5f5;
        border: 1px solid #ddd;
        border-radius: 4px;
        padding: 10px;
        max-height: 400px;
        overflow-y: auto;
    }

    .upload-input {
        display: none !important;
    }
</style>

<!-- Settings Form -->
{{ partial("layout_partials/base_form",['fields':generalForm,'id':'frm_GeneralSettings'])}}

<!-- Action Buttons -->
<div class="row">
    <div class="col-md-12">
        <hr />
        <button class="btn btn-primary" id="saveAct" type="button">
            <i class="fa fa-save"></i> {{ lang._('Save') }}
        </button>
        <button class="btn btn-info" id="testAct" type="button">
            <i class="fa fa-check-circle"></i> {{ lang._('Test Config') }}
        </button>
        <span id="saveMsg"></span>
    </div>
</div>

<!-- Binary Management Section -->
<div class="table-responsive" style="margin-top: 20px;">
    <table class="table table-striped table-condensed">
        <colgroup>
            <col style="width: 22%;" />
            <col style="width: 40%;" />
            <col style="width: 38%;" />
        </colgroup>
        <thead>
            <tr>
                <th colspan="3">
                    <div style="padding-bottom: 5px; padding-top: 5px; font-size: 16px;">
                        <i class="fa fa-cube"></i>&nbsp;<b>{{ lang._('Binary Management') }}</b>
                    </div>
                </th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><b>sing-box</b></td>
                <td>
                    <span class="label label-default" id="singboxVersion">{{ lang._('Loading...') }}</span>
                </td>
                <td style="text-align: right;">
                    <button class="btn btn-xs btn-warning" id="updateSingboxBtn" type="button">
                        <i class="fa fa-download"></i> {{ lang._('Update') }}
                    </button>
                    <button class="btn btn-xs btn-default" id="uploadSingboxBtn" type="button">
                        <i class="fa fa-upload"></i> {{ lang._('Upload') }}
                    </button>
                    <input type="file" id="singboxFileInput" class="upload-input" accept="*">
                </td>
            </tr>
            <tr>
                <td><b>hev-socks5-tunnel</b></td>
                <td>
                    <span class="label label-default" id="tun2socksVersion" title="">{{ lang._('Loading...') }}</span>
                </td>
                <td style="text-align: right;">
                    <button class="btn btn-xs btn-warning" id="updateTun2socksBtn" type="button">
                        <i class="fa fa-download"></i> {{ lang._('Update') }}
                    </button>
                    <button class="btn btn-xs btn-default" id="uploadTun2socksBtn" type="button">
                        <i class="fa fa-upload"></i> {{ lang._('Upload') }}
                    </button>
                    <input type="file" id="tun2socksFileInput" class="upload-input" accept="*">
                </td>
            </tr>
        </tbody>
    </table>
</div>

<!-- Log Viewer Section -->
<div class="table-responsive">
    <table class="table table-striped table-condensed">
        <colgroup>
            <col style="width: 22%;" />
            <col style="width: 78%;" />
        </colgroup>
        <thead>
            <tr>
                <th colspan="2">
                    <div style="padding-bottom: 5px; padding-top: 5px; font-size: 16px;">
                        <i class="fa fa-file-text-o"></i>&nbsp;<b>{{ lang._('Logs') }}</b>
                    </div>
                </th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td>{{ lang._('Controls') }}</td>
                <td>
                    <button class="btn btn-xs btn-default" id="refreshLogBtn" type="button">
                        <i class="fa fa-refresh"></i> {{ lang._('Refresh') }}
                    </button>
                    <label class="checkbox-inline" style="margin-left: 10px;">
                        <input type="checkbox" id="autoRefreshLog"> {{ lang._('Auto-refresh') }}
                    </label>
                </td>
            </tr>
            <tr>
                <td>{{ lang._('Output') }}</td>
                <td>
                    <div class="log-container" id="logContent">{{ lang._('Click Refresh to load logs...') }}</div>
                </td>
            </tr>
        </tbody>
    </table>
</div>

<!-- Output Modal -->
<div class="modal fade" id="outputModal" tabindex="-1" role="dialog">
    <div class="modal-dialog modal-lg" role="document">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal"><span>&times;</span></button>
                <h4 class="modal-title" id="outputModalTitle">{{ lang._('Output') }}</h4>
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
            var alertClass = isError ? "alert-danger" : "alert-success";
            $("#saveMsg")
                .removeClass("alert alert-success alert-danger")
                .addClass("alert " + alertClass)
                .css({"display": "inline-block", "padding": "6px 12px", "margin-left": "10px"})
                .html(message)
                .fadeIn()
                .delay(3000)
                .fadeOut(function() {
                    $(this).removeClass("alert " + alertClass);
                });
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
                    showMessage("{{ lang._('Saved') }}", false);
                } else {
                    showMessage("{{ lang._('Save failed') }}: " + (data.error || "Unknown error"), true);
                }
            });
        });

        // Test config button
        $("#testAct").click(function () {
            var config = $("#singbox\\.general\\.config").val();
            if (!config || config.trim() === "") {
                showMessage("{{ lang._('Configuration is empty') }}", true);
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
                            showMessage("{{ lang._('Configuration is valid!') }}", false);
                        } else {
                            showOutputModal("{{ lang._('Configuration Error') }}", output);
                        }
                    } else {
                        showMessage("{{ lang._('Test failed') }}: " + (data.error || "Unknown error"), true);
                    }
                },
                error: function () {
                    $("#testAct").prop('disabled', false);
                    showMessage("{{ lang._('Test request failed') }}", true);
                }
            });
        });

        // Update singbox button
        $("#updateSingboxBtn").click(function () {
            if (!confirm("{{ lang._('Update sing-box to the latest version? This will restart the service if running.') }}")) {
                return;
            }
            var btn = $(this);
            btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> {{ lang._("Updating...") }}');
            $.ajax({
                url: "/api/singbox/settings/updateSingbox",
                type: "POST",
                dataType: "json",
                success: function (data) {
                    btn.prop('disabled', false).html('<i class="fa fa-download"></i> {{ lang._("Update") }}');
                    if (data.result === "ok") {
                        showOutputModal("{{ lang._('Update sing-box') }}", data.output || "Update completed");
                        loadVersions();
                    } else {
                        showMessage("{{ lang._('Update failed') }}: " + (data.error || "Unknown error"), true);
                    }
                },
                error: function () {
                    btn.prop('disabled', false).html('<i class="fa fa-download"></i> {{ lang._("Update") }}');
                    showMessage("{{ lang._('Update request failed') }}", true);
                }
            });
        });

        // Update tun2socks button
        $("#updateTun2socksBtn").click(function () {
            if (!confirm("{{ lang._('Update hev-socks5-tunnel to the latest version? This will restart the service if running.') }}")) {
                return;
            }
            var btn = $(this);
            btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> {{ lang._("Updating...") }}');
            $.ajax({
                url: "/api/singbox/settings/updateTun2socks",
                type: "POST",
                dataType: "json",
                success: function (data) {
                    btn.prop('disabled', false).html('<i class="fa fa-download"></i> {{ lang._("Update") }}');
                    if (data.result === "ok") {
                        showOutputModal("{{ lang._('Update hev-socks5-tunnel') }}", data.output || "Update completed");
                        loadVersions();
                    } else {
                        showMessage("{{ lang._('Update failed') }}: " + (data.error || "Unknown error"), true);
                    }
                },
                error: function () {
                    btn.prop('disabled', false).html('<i class="fa fa-download"></i> {{ lang._("Update") }}');
                    showMessage("{{ lang._('Update request failed') }}", true);
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

            if (!confirm("{{ lang._('Upload and install this file as the sing-box binary?') }}\n\n{{ lang._('File') }}: " + file.name)) {
                $(this).val('');
                return;
            }

            var formData = new FormData();
            formData.append('file', file);

            var btn = $("#uploadSingboxBtn");
            btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> {{ lang._("Uploading...") }}');

            $.ajax({
                url: "/api/singbox/settings/uploadSingbox",
                type: "POST",
                data: formData,
                processData: false,
                contentType: false,
                dataType: "json",
                success: function (data) {
                    btn.prop('disabled', false).html('<i class="fa fa-upload"></i> {{ lang._("Upload") }}');
                    if (data.result === "ok") {
                        showOutputModal("{{ lang._('Upload sing-box') }}", data.output || "Upload completed");
                        loadVersions();
                    } else {
                        showMessage("{{ lang._('Upload failed') }}: " + (data.error || "Unknown error"), true);
                    }
                },
                error: function () {
                    btn.prop('disabled', false).html('<i class="fa fa-upload"></i> {{ lang._("Upload") }}');
                    showMessage("{{ lang._('Upload request failed') }}", true);
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

            if (!confirm("{{ lang._('Upload and install this file as the hev-socks5-tunnel binary?') }}\n\n{{ lang._('File') }}: " + file.name)) {
                $(this).val('');
                return;
            }

            var formData = new FormData();
            formData.append('file', file);

            var btn = $("#uploadTun2socksBtn");
            btn.prop('disabled', true).html('<i class="fa fa-spinner fa-spin"></i> {{ lang._("Uploading...") }}');

            $.ajax({
                url: "/api/singbox/settings/uploadTun2socks",
                type: "POST",
                data: formData,
                processData: false,
                contentType: false,
                dataType: "json",
                success: function (data) {
                    btn.prop('disabled', false).html('<i class="fa fa-upload"></i> {{ lang._("Upload") }}');
                    if (data.result === "ok") {
                        showOutputModal("{{ lang._('Upload hev-socks5-tunnel') }}", data.output || "Upload completed");
                        loadVersions();
                    } else {
                        showMessage("{{ lang._('Upload failed') }}: " + (data.error || "Unknown error"), true);
                    }
                },
                error: function () {
                    btn.prop('disabled', false).html('<i class="fa fa-upload"></i> {{ lang._("Upload") }}');
                    showMessage("{{ lang._('Upload request failed') }}", true);
                }
            });

            $(this).val('');
        });
    });
</script>