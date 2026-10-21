"""Pure-PyTorch CPU shim of NATTEN 0.14 functional API (natten1d/2d qkrpb & av)."""
import torch

def _nbr_index(L, K, d, device):
    i = torch.arange(L, device=device)
    r = i % d
    g = i // d
    Lg = (L - r + d - 1) // d               # length of each residue group
    start = torch.clamp(g - K // 2, min=0)
    start = torch.minimum(start, Lg - K)
    n = torch.arange(K, device=device)
    kg = start[:, None] + n[None, :]          # group coords of keys
    idx = kg * d + r[:, None]                 # absolute key positions [L,K]
    rel = kg - g[:, None] + (K - 1)           # rpb index [L,K]
    return idx, rel

def natten1dqkrpb(q, k, rpb, kernel_size, dilation):
    B, H, L, D = q.shape
    idx, rel = _nbr_index(L, kernel_size, dilation, q.device)
    kk = k[:, :, idx, :]                      # B,H,L,K,D
    attn = torch.einsum('bhld,bhlkd->bhlk', q, kk)
    if rpb is not None:
        attn = attn + rpb[:, rel].unsqueeze(0)
    return attn

def natten1dav(attn, v, kernel_size, dilation):
    B, H, L, D = v.shape
    idx, _ = _nbr_index(L, kernel_size, dilation, v.device)
    vv = v[:, :, idx, :]
    return torch.einsum('bhlk,bhlkd->bhld', attn, vv)

def natten2dqkrpb(q, k, rpb, kernel_size, dilation):
    B, H, X, Y, D = q.shape
    K = kernel_size
    ix, rx = _nbr_index(X, K, dilation, q.device)
    iy, ry = _nbr_index(Y, K, dilation, q.device)
    kk = k[:, :, ix[:, None, :, None], iy[None, :, None, :], :]   # B,H,X,Y,K,K,D
    attn = torch.einsum('zhxyd,zhxyabd->zhxyab', q, kk)
    if rpb is not None:
        bias = rpb[:, rx[:, None, :, None], ry[None, :, None, :]]  # H,X,Y,K,K
        attn = attn + bias.unsqueeze(0)
    return attn.reshape(B, H, X, Y, K * K)

def natten2dav(attn, v, kernel_size, dilation):
    B, H, X, Y, D = v.shape
    K = kernel_size
    ix, _ = _nbr_index(X, K, dilation, v.device)
    iy, _ = _nbr_index(Y, K, dilation, v.device)
    vv = v[:, :, ix[:, None, :, None], iy[None, :, None, :], :]
    a = attn.reshape(B, H, X, Y, K, K)
    return torch.einsum('zhxyab,zhxyabd->zhxyd', a, vv)
