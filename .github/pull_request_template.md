# Pull Request

## 📝 Description

Brief description of the changes in this PR.

Fixes #(issue)

## 🔄 Type of Change

- [ ] 🐛 Bug fix (non-breaking change which fixes an issue)
- [ ] ✨ New feature (non-breaking change which adds functionality)
- [ ] 💥 Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] 📚 Documentation update
- [ ] 🎨 Code style update (formatting, renaming)
- [ ] ♻️ Refactoring (no functional changes)
- [ ] 🧪 Test update
- [ ] 🔧 Configuration change

## 🧪 Testing

Describe the tests you ran to verify your changes:

- [ ] Syntax validation (`bash -n script.sh`)
- [ ] Validation script (`bash scripts/utils/validation.sh`)
- [ ] Test suite (`bash test_brainvault.sh`)
- [ ] Dry-run mode (`sudo ./brainvault_elite.sh --dry-run`)
- [ ] Full installation test (in VM)
- [ ] Manual testing

**Test Configuration:**
- OS: [e.g., Ubuntu 22.04]
- Environment: [e.g., VirtualBox VM]

## 📋 Checklist

### Code Quality
- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes

### Module Requirements (if applicable)
- [ ] Module sources `utils/logging.sh`
- [ ] Module supports dry-run mode
- [ ] All functions have error handling
- [ ] All public functions are exported
- [ ] Module is properly documented

### Documentation
- [ ] README.md updated (if needed)
- [ ] CHANGELOG.md updated
- [ ] Module documentation added/updated (if applicable)
- [ ] Examples provided (if applicable)

### Testing
- [ ] All bash scripts pass syntax validation
- [ ] No shellcheck warnings (or documented exceptions)
- [ ] Test suite passes
- [ ] Dry-run completes successfully
- [ ] Tested on Ubuntu 22.04 (minimum)

## 📸 Screenshots (if applicable)

Add screenshots to demonstrate the changes.

## 📊 Performance Impact

Does this change affect performance?
- [ ] No performance impact
- [ ] Improves performance
- [ ] May impact performance (explained below)

**Details**: 

## 🔐 Security Impact

Does this change affect security?
- [ ] No security impact
- [ ] Improves security
- [ ] Requires security review

**Details**:

## 💥 Breaking Changes

Does this PR introduce breaking changes?
- [ ] No breaking changes
- [ ] Yes (described below with migration guide)

**Migration Guide** (if applicable):
```bash
# Steps to migrate from old version
```

## 📝 Additional Notes

Any additional information reviewers should know.

## 🔗 Related Issues/PRs

- Related to #
- Depends on #
- Blocks #

---

**By submitting this pull request, I confirm that my contribution is made under the terms of the MIT License.**
