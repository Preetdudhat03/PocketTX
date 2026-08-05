using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;

namespace PocketTX.Companion.Services.Messages;

public sealed record ChannelUpdatedMessage(ChannelData ChannelData);
public sealed record ConnectionStateChangedMessage(ConnectionType ConnectionType, bool IsConnected);
public sealed record ProfileChangedMessage(ControllerProfile Profile);
public sealed record SimulatorStatusChangedMessage(SimulatorStatus Status);
public sealed record DiagnosticMetricsUpdatedMessage(DiagnosticMetrics Metrics);
public sealed record ThemeChangedMessage(ThemeType Theme);
