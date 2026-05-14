import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:krishikranti/core/cart_service.dart';
import 'package:krishikranti/core/profile_service.dart';
import 'package:provider/provider.dart';
import 'package:krishikranti/l10n/app_localizations.dart';
import 'package:krishikranti/screens/edit_address_screen.dart';
import 'package:krishikranti/screens/checkout_screen.dart';
import 'package:krishikranti/core/address_service.dart';

class ShippingAddressScreen extends StatefulWidget {
  const ShippingAddressScreen({super.key});

  @override
  State<ShippingAddressScreen> createState() => _ShippingAddressScreenState();
}

class _ShippingAddressScreenState extends State<ShippingAddressScreen> {
  final Color primaryGreen = const Color(0xFF2E7D32);
  String? selectedAddressId;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    final addressService = Provider.of<AddressService>(context, listen: false);
    final profileService = Provider.of<ProfileService>(context, listen: false);

    if (addressService.addresses.isNotEmpty) {
      selectedAddressId = addressService.addresses
          .firstWhere(
            (a) => a.isDefault,
            orElse: () => addressService.addresses.first,
          )
          .id;
      _isInitializing = false;
    } else if (profileService.user != null) {
      final profile = profileService.user!;
      final initialAddress = AddressModel(
        id: "default_home",
        name: profile.name.isNotEmpty ? profile.name : "Home / Shop",
        villageArea: profile.address?.villageArea ?? "",
        cityTehsil: profile.address?.cityTehsil ?? "",
        state: profile.address?.state ?? "",
        pincode: profile.address?.pincode ?? "",
        phoneNumber: profile.phoneNumber,
        isDefault: true,
      );
      addressService.setInitialLocalAddress(initialAddress);
      selectedAddressId = initialAddress.id;
      _isInitializing = false;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (addressService.addresses.isEmpty ||
          addressService.addresses.first.id == "default_home") {
        await addressService.fetchAddresses(background: true);

        if (mounted) {
          if (addressService.addresses.isEmpty && profileService.user != null) {
            // Promote profile address to first shipping address
            final profile = profileService.user!;
            final initialAddress = AddressModel(
              id: "",
              name: profile.name.isNotEmpty ? profile.name : "Home / Shop",
              villageArea: profile.address?.villageArea ?? "",
              cityTehsil: profile.address?.cityTehsil ?? "",
              state: profile.address?.state ?? "",
              pincode: profile.address?.pincode ?? "",
              phoneNumber: profile.phoneNumber,
              isDefault: true,
            );
            await addressService.addAddress(initialAddress);
          }

          if (addressService.addresses.isNotEmpty) {
            setState(() {
              selectedAddressId = addressService.addresses
                  .firstWhere(
                    (a) => a.isDefault,
                    orElse: () => addressService.addresses.first,
                  )
                  .id;
            });
          }
          setState(() => _isInitializing = false);
        }
      } else {
        addressService.fetchAddresses(background: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final addressService = Provider.of<AddressService>(context);
    final profileService = Provider.of<ProfileService>(context);
    final cartService = Provider.of<CartService>(context, listen: false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              CupertinoIcons.back,
              color: Colors.black,
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            l10n.shippingAddress,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          minimum: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              // Add Address Section
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    InkWell(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditAddressScreen(),
                          ),
                        );
                        if (result != null && result is AddressModel) {
                          final success = await addressService.addAddress(
                            result,
                          );
                          if (success) {
                            setState(
                              () => selectedAddressId =
                                  addressService.addresses.last.id,
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryGreen.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              CupertinoIcons.plus_circle_fill,
                              size: 16,
                              color: primaryGreen,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.addAddress,
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Address List
              Expanded(
                child: (addressService.isLoading || _isInitializing)
                    ? const Center(child: CircularProgressIndicator())
                    : addressService.addresses.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: addressService.addresses.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final address = addressService.addresses[index];
                          final isSelected = selectedAddressId == address.id;

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? primaryGreen
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Selection Area
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedAddressId = address.id;
                                    });
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Radio Selection
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Icon(
                                          isSelected
                                              ? CupertinoIcons
                                                    .check_mark_circled_solid
                                              : CupertinoIcons.circle,
                                          color: isSelected
                                              ? primaryGreen
                                              : Colors.grey.shade400,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Address Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  (address.name.isNotEmpty && address.name != 'Home / Shop')
                                                      ? address.name
                                                      : (profileService.name.isNotEmpty ? profileService.name : 'Home / Shop'),
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                if (address.isDefault) ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.grey.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      l10n.defaultLabel,
                                                      style: const TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.grey,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              address.fullAddress,
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                height: 1.4,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              address.phoneNumber.isNotEmpty ? address.phoneNumber : profileService.phone,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Action Area (Separated)
                                Container(
                                  padding: const EdgeInsets.only(top: 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Colors.grey.shade100,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      _actionBtn(
                                        CupertinoIcons.pencil,
                                        l10n.edit,
                                        () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditAddressScreen(
                                                    address: address,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 20),
                                      _actionBtn(
                                        CupertinoIcons.trash,
                                        l10n.delete,
                                        () async {
                                          final success = await addressService
                                              .deleteAddress(address.id);
                                          if (success && mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Address deleted",
                                                ),
                                              ),
                                            );
                                          }
                                        },
                                        color: Colors.red.shade400,
                                      ),
                                      if (!address.isDefault) ...[
                                        const SizedBox(width: 20),
                                        _actionBtn(
                                          CupertinoIcons.star,
                                          "Make Default",
                                          () async {
                                            // Move selection instantly
                                            setState(
                                              () => selectedAddressId =
                                                  address.id,
                                            );

                                            final success = await addressService
                                                .setDefault(address.id);
                                            if (!success && mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Failed to update default address",
                                                  ),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),

              // Bottom Action Button
              Container(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  MediaQuery.of(context).viewPadding.bottom + 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: addressService.addresses.isEmpty
                        ? null
                        : () async {
                            HapticFeedback.mediumImpact();

                            // Final Sync Guard before payment
                            if (cartService.pendingSyncTask != null) {
                              await cartService.pendingSyncTask;
                            }

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CheckoutScreen(),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      l10n.deliverHere,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.location_slash,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noAddressesFound,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.addAddressToContinue,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color ?? Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
