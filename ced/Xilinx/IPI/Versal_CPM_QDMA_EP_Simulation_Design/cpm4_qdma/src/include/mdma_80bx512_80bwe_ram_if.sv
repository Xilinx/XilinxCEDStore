// ////////////////////////////////////////////////////////////////////////
// Copyright (C) 2019, Xilinx Inc - All rights reserved
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

`ifndef MDMA_80BX512_80BWE_RAM_IF_SV
`define MDMA_80BX512_80BWE_RAM_IF_SV

interface mdma_80bx512_80bwe_ram_if();
        logic   [8:0]   wadr; 
        logic           wen;
        logic   [79:0]  wdat;  
        logic           ren;
        logic   [8:0]   radr;
        logic   [79:0]  rdat;
        logic           rsbe;
        logic           rdbe;

        modport  m (
                output  wadr,
                output  wen,
                output  wdat,
                output  ren,
                output  radr,
                input   rdat,
                input   rsbe,
                input   rdbe
         );
        modport  s (
                input   wadr,
                input   wen,
                input   wdat,
                input   ren,
                input   radr,
                output  rdat,
                output  rsbe,
                output  rdbe
         );
endinterface

`endif
