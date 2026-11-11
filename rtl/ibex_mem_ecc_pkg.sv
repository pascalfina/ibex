
// Shared SECDED codec for 32 data bits plus one capability tag.
// Codeword layout: [39:33] ECC, [32] capability tag, [31:0] data.
package ibex_mem_ecc_pkg;

  localparam logic [6:0] MemEccTagSyndrome = 7'h43;

  typedef struct packed {
    logic [31:0] data;
    logic        cap_tag;
    logic [6:0]  syndrome;
    logic [1:0]  err; // [0]: single-bit error, [1]: double-bit error.
  } mem_ecc_dec_t;

  function automatic logic [39:0] mem_ecc_encode(
    input logic [31:0] data_i,
    input logic        cap_tag_i
  );
    logic [38:0] encoded_data;
    logic [6:0] ecc;

    encoded_data = prim_secded_pkg::prim_secded_inv_39_32_enc(data_i);
    ecc = encoded_data[38:32] ^ ({7{cap_tag_i}} & MemEccTagSyndrome);

    return {ecc, cap_tag_i, data_i};
  endfunction

  function automatic mem_ecc_dec_t mem_ecc_decode(
    input logic [39:0] codeword_i
  );
    logic [6:0] data_only_ecc;
    prim_secded_pkg::secded_inv_39_32_t decoded_data;
    mem_ecc_dec_t result;

    data_only_ecc = codeword_i[39:33] ^ ({7{codeword_i[32]}} & MemEccTagSyndrome);
    decoded_data = prim_secded_pkg::prim_secded_inv_39_32_dec(
        {data_only_ecc, codeword_i[31:0]});

    result.data     = decoded_data.data;
    result.cap_tag  = codeword_i[32] ^ (decoded_data.syndrome == MemEccTagSyndrome);
    result.syndrome = decoded_data.syndrome;
    result.err      = decoded_data.err;

    return result;
  endfunction

  localparam logic [39:0] MemEccZeroWord = mem_ecc_encode(32'b0, 1'b0);
  localparam logic [6:0] MemEccZeroEcc = MemEccZeroWord[39:33];

endpackage : ibex_mem_ecc_pkg
