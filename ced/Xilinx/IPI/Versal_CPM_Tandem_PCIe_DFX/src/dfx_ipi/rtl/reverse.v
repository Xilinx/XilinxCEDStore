// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2026, Advanced Micro Devices, Inc. All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

// This module reverses a word, nibble-by-nibble
module reverse #(
  parameter WIDTH=32
)(
  input      [WIDTH-1:0] din,
  output reg [WIDTH-1:0] dout
);

  integer ii;

  always @(*) begin
    for (ii=0; ii<WIDTH; ii=ii+4)
      dout[WIDTH-ii-4 +: 4] = din[ii +: 4];
  end

endmodule
