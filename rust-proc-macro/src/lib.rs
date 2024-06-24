extern crate proc_macro;
use proc_macro::TokenStream;

#[proc_macro]
pub fn camera_trackable(_item: TokenStream) -> TokenStream {
    TokenStream::new()
}