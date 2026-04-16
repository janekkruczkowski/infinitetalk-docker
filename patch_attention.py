import sys
path = "/opt/infinitetalk/wan/modules/attention.py"
s = open(path).read()
old = "    else:\n        assert FLASH_ATTN_2_AVAILABLE"
new = """    else:
        if not FLASH_ATTN_2_AVAILABLE:
            q_sdpa = q.unflatten(0, (b, lq)).transpose(1, 2).to(out_dtype)
            k_sdpa = k.unflatten(0, (b, lk)).transpose(1, 2).to(out_dtype)
            v_sdpa = v.unflatten(0, (b, lk)).transpose(1, 2).to(out_dtype)
            x = torch.nn.functional.scaled_dot_product_attention(
                q_sdpa, k_sdpa, v_sdpa, dropout_p=dropout_p, scale=softmax_scale, is_causal=causal)
            return x.transpose(1, 2).contiguous()
        assert FLASH_ATTN_2_AVAILABLE"""
if old in s:
    open(path, "w").write(s.replace(old, new))
    print("Patched attention.py")
else:
    print("Pattern not found, skipping")
