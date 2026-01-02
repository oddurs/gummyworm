# Test Fixtures

This directory contains test fixtures for gummyworm regression testing.

## Files

- `test.palette` - Custom palette file for testing palette loading
- `expected/` - Expected output files for regression testing

## Generating Test Images

Test images are generated dynamically using ImageMagick:

```bash
# 50x50 black-to-white gradient
convert -size 50x50 gradient:black-white test_gradient.png

# 30x30 red-to-blue gradient  
convert -size 30x30 gradient:red-blue test_color.png
```

## Expected Outputs

Expected output files are stored in `expected/` for regression testing.
These are used to verify that output format hasn't changed unexpectedly.
