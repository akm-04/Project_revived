package otabuild

import "fmt"

// The stock Android client reports download progress through a 32-bit float and
// keeps the local file offset in a signed 32-bit integer. These rules are the
// V1 mid2_compat planner, kept identical so a built payload always fits the
// client (ruling 5; work/oracles/v1/gxb_backend/updates/mid2_compat.py).
const (
	float32AllIntegerLimit int64 = 1 << 24
	float32TailAnchor      int64 = 1 << 23
	volumeSplitSearchLimit int64 = 256
)

func isFloat32Exact(value int64) bool {
	return value >= 0 && int64(float32(value)) == value
}

func largestFloat32ExactAtMost(value int64) (int64, error) {
	if value <= 0 {
		return 0, fmt.Errorf("%w: volume cap must be positive", ErrVolumeLimit)
	}
	// Below 2^31 the widest binary32 spacing is 128 bytes, so this is bounded.
	candidate := value
	for candidate > 0 && !isFloat32Exact(candidate) {
		candidate--
	}
	if candidate <= 0 {
		return 0, fmt.Errorf("%w: no exact volume size fits the cap", ErrVolumeLimit)
	}
	return candidate, nil
}

// planVolumeSizes returns the raw sizes for .001..NNN: positive, at most the
// cap, every size exactly representable by the client's float32 bridge, and
// summing to total.
func planVolumeSizes(total, cap int64) ([]int64, error) {
	if total <= 0 {
		return nil, fmt.Errorf("%w: the package is empty", ErrVolumeLimit)
	}
	if cap <= 0 {
		return nil, fmt.Errorf("%w: volume cap must be positive", ErrVolumeLimit)
	}
	if total >= maxTotalBytes {
		return nil, fmt.Errorf("%w: %d bytes do not fit under the signed-int32 total", ErrVolumeLimit, total)
	}
	full, err := largestFloat32ExactAtMost(cap)
	if err != nil {
		return nil, err
	}
	fullCount, remaining := total/full, total%full
	sizes := make([]int64, 0, fullCount+2)
	for range fullCount {
		sizes = append(sizes, full)
	}
	if remaining > 0 {
		if isFloat32Exact(remaining) {
			sizes = append(sizes, remaining)
		} else {
			parts, err := splitNonExactRemainder(remaining, cap)
			if err != nil {
				return nil, err
			}
			sizes = append(sizes, parts...)
		}
	}
	if err := checkVolumePlan(sizes, total, cap); err != nil {
		return nil, err
	}
	return sizes, nil
}

// splitNonExactRemainder keeps a small exact tail and aligns the large head to
// the float32 grid, avoiding a one-byte final volume.
func splitNonExactRemainder(remainder, cap int64) ([]int64, error) {
	if remainder <= 0 || remainder > cap {
		return nil, fmt.Errorf("%w: remainder %d does not fit the cap", ErrVolumeLimit, remainder)
	}
	if isFloat32Exact(remainder) {
		return []int64{remainder}, nil
	}
	if remainder <= float32AllIntegerLimit {
		return nil, fmt.Errorf("%w: %d must be float32-exact", ErrVolumeLimit, remainder)
	}
	tailStart := min(float32TailAnchor, remainder-1, cap)
	for delta := range volumeSplitSearchLimit {
		tail := tailStart + delta
		head := remainder - tail
		if tail <= 0 || head <= 0 || tail > cap || head > cap {
			continue
		}
		if isFloat32Exact(tail) && isFloat32Exact(head) {
			return []int64{head, tail}, nil
		}
	}
	return exactFallback(remainder, cap)
}

func exactFallback(remainder, cap int64) ([]int64, error) {
	chunk := min(float32AllIntegerLimit, cap)
	if chunk <= 0 {
		return nil, fmt.Errorf("%w: invalid fallback cap", ErrVolumeLimit)
	}
	sizes := make([]int64, 0, remainder/chunk+1)
	left := remainder
	for left > chunk {
		sizes = append(sizes, chunk)
		left -= chunk
	}
	if left > 0 {
		sizes = append(sizes, left)
	}
	for _, size := range sizes {
		if size <= 0 || size > cap || !isFloat32Exact(size) {
			return nil, fmt.Errorf("%w: fallback volume plan is not exact", ErrVolumeLimit)
		}
	}
	return sizes, nil
}

func checkVolumePlan(sizes []int64, total, cap int64) error {
	if len(sizes) == 0 {
		return fmt.Errorf("%w: no volume", ErrVolumeLimit)
	}
	var sum, prefix int64
	for _, size := range sizes {
		if size <= 0 || size > cap {
			return fmt.Errorf("%w: volume size %d is outside the cap", ErrVolumeLimit, size)
		}
		if !isFloat32Exact(size) {
			return fmt.Errorf("%w: volume size %d is not float32-exact", ErrVolumeLimit, size)
		}
		if prefix > maxTotalBytes {
			return fmt.Errorf("%w: prefix offset exceeds the signed-int32 total", ErrVolumeLimit)
		}
		prefix += size
		sum += size
	}
	if sum != total {
		return fmt.Errorf("%w: volumes total %d, package is %d", ErrVolumeLimit, sum, total)
	}
	return nil
}
