// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
//
// Licensed under the Apache License, Version 2.0 (the "License"). You may
// not use this file except in compliance with the License. A copy of the
// License is located at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.
// ////////////////////////////////////////////////////////////////////////

`timescale 1ps/1ps

module sys_clk_gen_ds (sys_clk_p, sys_clk_n);

output	         sys_clk_p;
output	         sys_clk_n;

parameter        offset = 0;
parameter        halfcycle = 500;


sys_clk_gen 	#(

                 .offset( offset ),
                 .halfcycle( halfcycle )

)
clk_gen (

                 .sys_clk(sys_clk_p)

);

assign sys_clk_n = !sys_clk_p;

endmodule // sys_clk_gen_ds
