path = "/opt/infinitetalk/wan/utils/multitalk_utils.py"
s = open(path).read()
old = """from xfuser.core.distributed import (
    get_sequence_parallel_rank,
    get_sequence_parallel_world_size,
    get_sp_group,
)"""
new = """try:
    from xfuser.core.distributed import (
        get_sequence_parallel_rank,
        get_sequence_parallel_world_size,
        get_sp_group,
    )
except ImportError:
    def get_sequence_parallel_rank(): return 0
    def get_sequence_parallel_world_size(): return 1
    def get_sp_group(): return None"""
if old in s:
    open(path, "w").write(s.replace(old, new))
    print("Patched xfuser import")
else:
    print("xfuser pattern not found, skipping")
