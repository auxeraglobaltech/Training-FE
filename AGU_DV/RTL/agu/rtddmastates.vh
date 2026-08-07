`ifndef RTDDMASTATES_VH
`define RTDDMASTATES_VH

`include "rtddmaparams.vh"

// -----------------------------------------------------------------------------
// RTD-DMA State Encodings
// This header is intentionally redundant. If two states have similar names, both
// names are defined to the same encoding so legacy RTL and verification compile.
// -----------------------------------------------------------------------------

// Base generic 3-bit state set
`define RTDDMAIDLES                      3'd0
`define RTDDMAIDLE                       3'd0
`define RTDDMABUSYS                      3'd1
`define RTDDMABUSY                       3'd1
`define RTDDMADONES                      3'd2
`define RTDDMADONE                       3'd2
`define RTDDMAABORTS                     3'd3
`define RTDDMAABORT                      3'd3
`define RTDDMAFAULTS                     3'd4
`define RTDDMAFAULT                      3'd4
`define RTDDMAPAUSES                     3'd5
`define RTDDMAPAUSE                      3'd5
`define RTDDMADRAINS                     3'd6
`define RTDDMADRAIN                      3'd6
`define RTDDMALOADS                      3'd7
`define RTDDMALOAD                       3'd7

// AGU compact states used in current AGU sub-blocks
`define RTDDMAAGUSTIDLE                  3'd0
`define RTDDMAAGUSTACTIVE                3'd1
`define RTDDMAAGUSTDONE                  3'd2
`define RTDDMAAGUSTABORT                 3'd3
`define RTDDMAAGUSTFAULT                 3'd4
`define RTDDMAAGUSTPAUSE                 3'd5
`define RTDDMAAGUSTDRAIN                 3'd6
`define RTDDMAAGUSTLOAD                  3'd7

// Detailed AGU architecture names from microarchitecture spec.
// These are intentionally declared even if they alias to the compact set.
`define AGUIDLE                          3'd0
`define AGULOAD                          3'd7
`define AGUISSUE                         3'd1
`define AGUNEXTX                         3'd1
`define AGUNEXTY                         3'd1
`define AGUSWAP                          3'd5
`define AGUDONE                          3'd2
`define AGUFAULT                         3'd4

`define RTDDMAAGUSTISSUE                 3'd1
`define RTDDMAAGUSTNEXTX                 3'd1
`define RTDDMAAGUSTNEXTY                 3'd1
`define RTDDMAAGUSTSWAP                  3'd5

// Trigger Control Unit states from architecture spec
`define TCUIDLE                          3'd0
`define TCUWAITWINDOW                    3'd1
`define TCUQUALIFY                       3'd2
`define TCUFIRE                          3'd3
`define TCUBUSYHOLD                      3'd4
`define TCUREJECT                        3'd5

// Descriptor fetch states from architecture spec
`define DFMIDLE                          4'd0
`define DFMREQ                           4'd1
`define DFMWAITRDATA                     4'd2
`define DFMCAPTURE                       4'd3
`define DFMVALIDATE                      4'd4
`define DFMLOADACTIVE                    4'd5
`define DFMLOADSHADOW                    4'd6
`define DFMNEXTDESC                      4'd7
`define DFMDONE                          4'd8
`define DFMFAULT                         4'd9

// Preemption states from architecture spec
`define PREIDLE                          3'd0
`define PREMONITOR                       3'd1
`define PREREQPENDING                    3'd2
`define PREWAITSAFEBOUNDARY              3'd3
`define PREGRANTSWAP                     3'd4
`define PRERESUME                        3'd5
`define PREFAULT                         3'd6

// Additional control / safety names mentioned in diagrams and docs.
`define ISSUEIDLE                        3'd0
`define ISSUEISSUE                       3'd1
`define ISSUEDRAIN                       3'd6
`define ISSUEABORT                       3'd3
`define ISSUEDONE                        3'd2
`define ISSUEFAULT                       3'd4

`define SWAPIDLE                         3'd0
`define SWAPACTIVE                       3'd1
`define SWAPBOUNDARYCHECK                3'd2
`define SWAPCOMMIT                       3'd3
`define SWAPDONE                         3'd4
`define SWAPFAULT                        3'd5
`define RTDDMA_IDLE_S       `RTDDMAIDLES
`define RTDDMA_BUSY_S       `RTDDMABUSYS
`define RTDDMA_DONE_S       `RTDDMADONES
`define RTDDMA_ABORT_S      `RTDDMAABORTS
`define RTDDMA_FAULT_S      `RTDDMAFAULTS
`define RTDDMA_PAUSE_S      `RTDDMAPAUSES
`define RTDDMA_DRAIN_S      `RTDDMADRAINS
`define RTDDMA_LOAD_S       `RTDDMALOADS

`define RTDDMA_AGU_ST_IDLE    `RTDDMAAGUSTIDLE
`define RTDDMA_AGU_ST_ACTIVE  `RTDDMAAGUSTACTIVE
`define RTDDMA_AGU_ST_DONE    `RTDDMAAGUSTDONE
`define RTDDMA_AGU_ST_ABORT   `RTDDMAAGUSTABORT
`define RTDDMA_AGU_ST_FAULT   `RTDDMAAGUSTFAULT
`define RTDDMA_AGU_ST_PAUSE   `RTDDMAAGUSTPAUSE
`define RTDDMA_AGU_ST_DRAIN   `RTDDMAAGUSTDRAIN
`define RTDDMA_AGU_ST_LOAD    `RTDDMAAGUSTLOAD
`endif
